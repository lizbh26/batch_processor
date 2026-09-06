const std = @import("std");
const Operation = @import("operation.zig");

pub const Process = struct {
    id: []const u8,
    batchIdx: usize,

    username: []const u8,

    operation: Operation.Operation,
    tme_ms: i128,
    tt_ms: i128 = 0,

    pub fn seed(self: *Process, alloc: std.mem.Allocator, data: struct { id: u16, batchIdx: usize }) void {
        self.id = std.fmt.allocPrint(alloc, "{d}", .{data.id}) catch "ID COULD NOT BE GENERATED";
        self.batchIdx = data.batchIdx;
        self.operation = .{ .a = 65, .b = 43, .operand = .sum, .result = null };
        self.tme_ms = 2000;
        self.tt_ms = 0;
    }

    pub fn isDone(self: *const Process) bool {
        return self.tme_ms <= self.tt_ms;
    }
};
