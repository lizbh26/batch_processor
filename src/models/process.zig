const Operation = @import("operation.zig");

pub const Process = struct {
    id: []const u8 = "",
    operation: Operation.Operation,
    tme: u32 = 0,
    tt: u32 = 0,

    pub fn seed(self: *Process) void {
        self.id = "dont do this";
        self.operation = .{ .a = 65, .b = 43, .operand = .sum };
        self.tme = 5;
        self.tt = 0;
    }
};
