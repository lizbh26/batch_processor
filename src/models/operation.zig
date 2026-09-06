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

    pub fn fromString(_: []const u8) Operation {
        return .{ .a = 5, .operand = .sum, .b = -54, .result = null };
    }
};
