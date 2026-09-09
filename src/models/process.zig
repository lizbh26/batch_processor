const std = @import("std");
const Operation = @import("operation.zig");

pub const Process = struct {
    id: usize,
    batchIdx: usize,

    operation: Operation.Operation,
    tme_ms: i128,
    tt_ms: i128 = 0,

    pub fn seed(self: *Process, random: std.Random, data: struct { id: usize, batchIdx: usize }) void {
        self.id = data.id;
        self.batchIdx = data.batchIdx;
        self.operation.seed(random);
        self.tme_ms = random.intRangeAtMost(i128, 1, 5) * 1000;
        self.tt_ms = 0;
    }

    pub fn isDone(self: *const Process) bool {
        return self.tme_ms <= self.tt_ms;
    }
};
