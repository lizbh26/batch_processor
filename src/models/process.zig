const std = @import("std");
const zeit = @import("zeit");

const Operation = @import("operation.zig");

pub const Process = struct {
    id: []const u8,

    operation: Operation.Operation,
    tme_ms: i128,
    tt_ms: i128 = 0,

    arrival_time: zeit.Instant,
    starting_time: ?zeit.Instant,
    finalization_time: zeit.Instant,

    pub fn seed(self: *Process, random: std.Random, alloc: std.mem.Allocator, data: struct { id: usize }) !void {
        self.id = try std.fmt.allocPrint(alloc, "{d}", .{data.id});
        self.operation.seed(random);

        self.tme_ms = random.intRangeAtMost(i128, 5, 20) * 1000;
        self.tt_ms = 0;

        self.starting_time = null;
    }

    pub fn isDone(self: *const Process) bool {
        return self.tme_ms <= self.tt_ms;
    }
};

pub const BlockedProcess = struct {
    p: *Process,
    ellapsed_ms: i128,

    pub fn init(self: *BlockedProcess, p: *Process) void {
        self.p = p;
        self.ellapsed_ms = 0;
    }

    pub fn isDone(self: *const BlockedProcess) bool {
        return self.ellapsed_ms > BLOCKED_TIME_MS;
    }
};
pub const BLOCKED_TIME_MS = 8000;
