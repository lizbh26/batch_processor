const std = @import("std");

var prng: std.Random.DefaultPrng = .init(blk: {
    var seed: u64 = undefined;
    std.posix.getrandom(std.mem.asBytes(&seed));
    break :blk seed;
});
const rand = prng.random();

pub fn generateRandomNumber(comptime T: type, a: T, b: T) u16 {
    return rand.intRangeAtMost(T, a, b);
}
