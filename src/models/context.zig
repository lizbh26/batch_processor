const std = @import("std");
const Process = @import("process.zig");
const Queue = @import("queue.zig").Queue;

const zeit = @import("zeit");

const usize_to = @import("../utils/index.zig").usize_to;

pub const MAX_PROCESSES_IN_MEMORY = 5;

var NULL_PROCESS: Process.Process = .{ .id = 0, .arrival_time = zeit.instant(.{ .unix_nano = 0 }, &zeit.utc), .finalization_time = zeit.instant(.{ .unix_nano = 0 }, &zeit.utc), .operation = .{ .a = 0, .b = 0, .operand = .sum, .result = null }, .starting_time = null, .tme_ms = 1, .tt_ms = 0 };

pub const ExecutionContext = struct {
    const Self = @This();

    arena: std.heap.ArenaAllocator,

    process_count: usize,

    new_queue: Queue(Process.Process),
    ready_queue: Queue(Process.Process),
    current_process: ?*Process.Process,
    blocked: [MAX_PROCESSES_IN_MEMORY]?Process.BlockedProcess,
    finished_queue: Queue(Process.Process),

    prev_tick: ?zeit.Instant,
    time_ellapsed_nano: i128,

    pub fn init(self: *Self, extern_alloc: std.mem.Allocator) void {
        self.arena = std.heap.ArenaAllocator.init(extern_alloc);
        self.process_count = 0;
        self.prev_tick = null;
        self.time_ellapsed_nano = 0;
    }
    pub fn deinit(self: *Self) void {
        self.arena.deinit();
    }

    pub fn create(self: *Self, random: std.Random, pCount: usize) !void {
        const alloc = self.arena.allocator();

        self.process_count = pCount;
        self.new_queue = try .init(alloc);
        self.ready_queue = try .init(alloc);
        self.current_process = null;
        self.blocked = [_]?Process.BlockedProcess{null} ** MAX_PROCESSES_IN_MEMORY;
        self.finished_queue = try .init(alloc);

        const processes = try alloc.alloc(Process.Process, pCount);

        for (processes, 0..) |*p, i| {
            p.seed(random, .{ .id = i + 1 });
            self.new_queue.enqueue(p) catch unreachable;
        }
    }

    pub fn tick(self: *Self, now: zeit.Instant) !void {
        if (self.isComplete()) return;

        if (self.prev_tick) |prev| {
            const delta_nano = now.timestamp - prev.timestamp;
            self.time_ellapsed_nano += delta_nano;

            const delta_ms = zeit.instant(.{ .unix_nano = delta_nano }, &zeit.utc).milliTimestamp();

            try self.tickBlockedProcesses(delta_ms);
            try self.fillConcurrentProcesses(now);
            try self.executeCurrentProcess(now, delta_ms);
        }

        self.prev_tick = now;
    }
    pub fn stop(self: *Self) void {
        self.prev_tick = null;
    }

    fn countBlockedProcesses(self: Self) usize {
        var i: usize = 0;
        for (self.blocked) |b| {
            if (b != null) i += 1;
        }
        return i;
    }
    fn countProcessesInMemory(self: Self) usize {
        return self.ready_queue.len + self.countBlockedProcesses();
    }
    fn fillConcurrentProcesses(self: *Self, now: zeit.Instant) !void {
        var count = self.countProcessesInMemory();
        while (count < MAX_PROCESSES_IN_MEMORY - 1) {
            const p = self.new_queue.dequeue() catch break;
            try self.ready_queue.enqueue(p);
            p.arrival_time = now;
            count += 1;
        }
    }
    fn executeCurrentProcess(self: *Self, now: zeit.Instant, delta_ms: i128) !void {
        if (self.current_process == null) {
            self.current_process = self.ready_queue.dequeue() catch return;
        }
        const p = self.current_process.?;

        if (p.starting_time == null) p.starting_time = now else p.tt_ms += delta_ms;
        if (p.isDone()) {
            try self.completeCurrentProcess(now);
        }
    }
    fn tickBlockedProcesses(self: *Self, delta_ms: i128) !void {
        for (&self.blocked) |*blocked| {
            const bp = &(blocked.* orelse continue);
            if (bp.ellapsed_ms < Process.BLOCKED_TIME_MS) {
                bp.ellapsed_ms += delta_ms;
            } else {
                try self.ready_queue.enqueue(bp.p);
                blocked.* = null;
            }
        }
    }

    pub fn getCurrentProcess(self: *Self) *Process.Process {
        return self.current_process orelse {
            NULL_PROCESS.tt_ms = 0;
            return &NULL_PROCESS;
        };
    }
    pub fn completeCurrentProcess(self: *Self, now: zeit.Instant) !void {
        if (self.current_process == null) return error.InvalidAccess;
        self.current_process.?.operation.calculate();
        try self.moveCurrentToFinalized(now);
    }
    pub fn failCurrentProcess(self: *Self, now: zeit.Instant) !void {
        try self.moveCurrentToFinalized(now);
    }
    fn moveCurrentToFinalized(self: *Self, now: zeit.Instant) !void {
        const p = self.current_process orelse return error.InvalidAccess;
        p.finalization_time = now;
        try self.finished_queue.enqueue(p);
        self.current_process = self.ready_queue.dequeue() catch null;
    }

    pub fn blockCurrentProcess(self: *Self) void {
        const p = self.current_process orelse return;
        for (&self.blocked) |*bp| {
            if (bp.* == null) {
                bp.* = .{ .p = p, .ellapsed_ms = 0 };
                self.current_process = null;
                return;
            }
        }
        unreachable;
    }

    pub fn isComplete(self: Self) bool {
        return self.finished_queue.len == self.process_count;
    }
};

fn divideWithRemainder(comptime T: type, a: T, b: T) struct { T, T } {
    var div: T = 0;
    var rem = a;

    while (rem >= b) {
        rem -= b;
        div += 1;
    }
    return .{ div, rem };
}
