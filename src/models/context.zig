const std = @import("std");
const Process = @import("process.zig");
const Queue = @import("queue.zig").Queue;

const zeit = @import("zeit");

const usize_to = @import("../utils/index.zig").usize_to;

pub const MAX_PROCESSES_IN_MEMORY = 5;

var NULL_PROCESS: Process.Process = .{ .id = "NULO", .arrival_time = zeit.instant(.{ .unix_nano = 0 }, &zeit.utc), .finalization_time = zeit.instant(.{ .unix_nano = 0 }, &zeit.utc), .operation = .{ .a = 0, .b = 0, .operand = .sum, .result = null }, .starting_time = null, .tme_ms = 1, .tt_ms = 0 };

pub const ExecutionContext = struct {
    const Self = @This();

    arena: std.heap.ArenaAllocator,

    process_count: usize,

    new_queue: Queue(Process.Process),
    ready_queue: Queue(Process.Process),
    current_process: ?*Process.Process,
    blocked_queue: Queue(Process.BlockedProcess),
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
        self.blocked_queue = try .init(alloc);
        self.finished_queue = try .init(alloc);

        const processes = try alloc.alloc(Process.Process, pCount);

        for (processes, 0..) |*p, i| {
            try p.seed(random, alloc, .{ .id = i + 1 });
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

    fn countProcessesInMemory(self: Self) usize {
        return self.ready_queue.len + self.blocked_queue.len;
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
        for (0..self.blocked_queue.len) |i| {
            const bp = self.blocked_queue.get(i) catch unreachable;
            bp.ellapsed_ms += delta_ms;
        }
        const top = self.blocked_queue.peek() catch return;
        if (top.isDone()) {
            try self.ready_queue.enqueue(top.p);
            _ = self.blocked_queue.dequeue() catch unreachable;
            self.arena.allocator().destroy(top);
        }
    }

    pub fn getCurrentProcess(self: *Self) *Process.Process {
        return self.current_process orelse &NULL_PROCESS;
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

    pub fn blockCurrentProcess(self: *Self) !void {
        const p = self.current_process orelse return;

        const blocked = try self.arena.allocator().create(Process.BlockedProcess);
        blocked.init(p);
        try self.blocked_queue.enqueue(blocked);

        self.current_process = null;
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
