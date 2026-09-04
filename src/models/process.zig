const Operation = @import("operation.zig");

pub const Process = struct {
    id: []const u8,
    operation: Operation.Operation,
    tme: u32,
    tt: u32,

    pub fn seed(self: *Process) void {
        self.id = "dont do this";
        self.operation = .{ .a = 65, .b = 43, .operand = .sum, .result = -1 };
        self.tme = 5;
        self.tt = 0;
    }

    pub fn isDone(_: *Process) bool {
        return true; //TODO: check time taken vs time estimated to check doneness
    }
};
