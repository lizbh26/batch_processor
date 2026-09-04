const std = @import("std");
pub fn leftpad(str: []const u8, by: usize, with: u8, alloc: std.mem.Allocator) []const u8 {
    defer alloc.free(str);

    const distinct_chars = count_distinct_utf8_chars(str);
    const whitespaces = str.len - distinct_chars + by;

    const new_str = alloc.alloc(u8, str.len + whitespaces) catch return str;

    for (0..whitespaces) |i| new_str[i] = with;
    for (str, 0..) |char, i| new_str[i + whitespaces] = char;
    return new_str;
}

fn count_distinct_utf8_chars(str: []const u8) usize {
    var utf8 = (std.unicode.Utf8View.init(str) catch return str.len).iterator();
    var distict_chars: usize = 0;
    while (utf8.nextCodepoint()) |_| {
        distict_chars += 1;
    }
    return distict_chars;
}
