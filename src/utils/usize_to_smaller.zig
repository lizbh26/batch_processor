const std = @import("std");
pub fn usize_to(comptime T: type, v: usize) T {
    const min = @min(v, @as(usize, std.math.maxInt(T)));
    return @intCast(min);
}
