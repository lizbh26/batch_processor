const std = @import("std");

const count_utf8 = @import("count_utf8.zig").count_utf8;
pub fn leftpad(str: []const u8, by: usize, with: u8, alloc: std.mem.Allocator) []const u8 {
    defer alloc.free(str);

    const distinct_chars = count_utf8(str);
    const whitespaces = str.len - distinct_chars + by;

    const new_str = alloc.alloc(u8, str.len + whitespaces) catch return str;

    for (0..whitespaces) |i| new_str[i] = with;
    for (str, 0..) |char, i| new_str[i + whitespaces] = char;
    return new_str;
}
