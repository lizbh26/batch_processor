const Operation = @import("operation.zig");

pub const Process = struct { id: []const u8 = "", operation: Operation.Operation, tme: u32 = 0 };
