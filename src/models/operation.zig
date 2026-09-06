const std = @import("std");

pub const Operand = enum { sum, diff, product, division, remainder };
pub const Operation = struct {
    a: i32 = 0,
    b: i32 = 0,
    operand: Operand = Operand.sum,
    result: ?i32,

    pub fn calculate(self: *Operation) void {
        if (self.result != null) return;
        self.result = switch (self.operand) {
            .sum => self.a + self.b,
            .diff => self.a - self.b,
            .product => self.a * self.b,
            .division => @divFloor(self.a, self.b),
            .remainder => @mod(self.a, self.b),
        };
    }

    pub fn toString(self: *Operation, alloc: std.mem.Allocator, displayResult: bool) ![]const u8 {
        const operand: u8 =
            switch (self.operand) {
                .sum => '+',
                .diff => '-',
                .product => 'x',
                .division => '/',
                .remainder => '%',
            };

        var op = try std.fmt.allocPrint(alloc, "{d} {c} {d}", .{ self.a, operand, self.b });
        if (displayResult and self.result != null) {
            const res = try std.fmt.allocPrint(alloc, " = {d}", .{self.result.?});
            defer alloc.free(res);

            const prevMem = (&op).*;
            defer alloc.free(prevMem);

            op = try std.mem.concat(alloc, u8, &.{ op, res });
        }
        return op;
    }
};

pub const ParsingError = error{ InvalidOperation, DivisionByZero, Overflow, InvalidCharacter };
pub fn fromString(str: []const u8) ParsingError!Operation {
    var op_index: ?usize = null;
    var op_type: ?Operand = null;
    var op_len: usize = 1; // Track operator length to slice 'b' correctly
    var i: usize = 0;

    // Skip leading whitespace
    while (i < str.len and std.ascii.isWhitespace(str[i])) : (i += 1) {}

    // Skip a leading '+' or '-'
    if (i < str.len and (str[i] == '-' or str[i] == '+')) {
        i += 1;
    }

    while (i < str.len) : (i += 1) {
        if (std.mem.startsWith(u8, str[i..], "mod")) {
            op_type = .remainder;
            op_index = i;
            op_len = 3;
            break;
        }

        switch (str[i]) {
            '+' => {
                op_type = .sum;
                op_index = i;
                break;
            },
            '-' => {
                op_type = .diff;
                op_index = i;
                break;
            },
            '*', 'x' => {
                op_type = .product;
                op_index = i;
                break;
            },
            '/' => {
                op_type = .division;
                op_index = i;
                break;
            },
            '%' => {
                op_type = .remainder;
                op_index = i;
                break;
            },
            else => continue,
        }
    }

    if (op_index == null or op_type == null) {
        return error.InvalidOperation;
    }

    const idx = op_index.?;

    // Split string and trim whitespace on both ends of both operands
    const a_str = std.mem.trim(u8, str[0..idx], &std.ascii.whitespace);
    const b_str = std.mem.trim(u8, str[idx + op_len ..], &std.ascii.whitespace);

    const a = try std.fmt.parseInt(i32, a_str, 10);
    const b = try std.fmt.parseInt(i32, b_str, 10);

    if (op_type.? == .division and b == 0) return error.DivisionByZero;

    return Operation{
        .a = a,
        .b = b,
        .operand = op_type.?,
        .result = null,
    };
}
