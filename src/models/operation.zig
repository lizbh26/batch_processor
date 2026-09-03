const std = @import("std");

pub const Operand = enum { sum, diff, product, division, remainder };
pub const Operation = struct {
    a: i32 = 0,
    b: i32 = 0,
    operand: Operand = Operand.sum,
    pub fn calculate(self: *Operation) i32 {
        switch (self.operand) {
            .sum => return self.a + self.b,
            .diff => return self.a - self.b,
            .product => return self.a * self.b,
            .division => return self.a / self.b,
            .remainder => return self.a % self.b,
        }
        return 0;
    }

    pub fn toString(self: *Operation, alloc: std.mem.Allocator) ![]const u8 {
        const operand: u8 =
            switch (self.operand) {
                .sum => '+',
                .diff => '-',
                .product => 'x',
                .division => '/',
                .remainder => '%',
            };

        return try std.fmt.allocPrint(alloc, "{d} {c} {d}", .{ self.a, operand, self.b });
    }
};
