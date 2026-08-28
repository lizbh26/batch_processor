pub const Operand = enum { sum, diff, product, division, remainder };
pub const Operation = struct {
    a: i32 = 0,
    b: i32 = 0,
    operand: Operand = Operand.sum,
    pub fn calculate(self: *Operation) i32 {
        switch (self.operand) {
            Operand.sum => return self.a + self.b,
            Operand.diff => return self.a - self.b,
            Operand.product => return self.a * self.b,
            Operand.division => return self.a / self.b,
            Operand.remainder => return self.a % self.b,
        }
        return 0;
    }
};
