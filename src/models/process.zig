const std = @import("std");
const Operation = @import("operation.zig");

pub const Process = struct {
    id: []const u8,
    operation: Operation.Operation,
    tme_ms: i128,
    tt_ms: i128,

    pub fn seed(self: *Process, alloc: std.mem.Allocator, id: u16) void {
        self.id = std.fmt.allocPrint(alloc, "{d}", .{id}) catch "ID COULD NOT BE GENERATED";
        self.operation = .{ .a = 65, .b = 43, .operand = .sum, .result = -1 };
        self.tme_ms = 5000;
        self.tt_ms = 0;
    }

    pub fn isDone(self: *Process) bool {
        return self.tme_ms <= self.tt_ms;
    }
};
