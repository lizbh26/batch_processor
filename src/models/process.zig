const std = @import("std");
const Operation = @import("operation.zig");

const generateRand = @import("../utils/random_number.zig").generateRandomNumber;

pub const Process = struct {
    id: u16,
    batchIdx: usize,

    username: []const u8,

    operation: Operation.Operation,
    tme_ms: i128,
    tt_ms: i128 = 0,

    pub fn seed(self: *Process, data: struct { id: u16, batchIdx: usize }) void {
        self.id = data.id;
        self.batchIdx = data.batchIdx;
        self.operation.seed();
        self.tme_ms = generateRand(u8, 4, 12) * 1000;
        self.tt_ms = 0;
    }

    pub fn isDone(self: *const Process) bool {
        return self.tme_ms <= self.tt_ms;
    }
};
