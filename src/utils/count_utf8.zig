const std = @import("std");

pub fn count_utf8(str: []const u8) usize {
    var utf8 = (std.unicode.Utf8View.init(str) catch return str.len).iterator();
    var distict_chars: usize = 0;
    while (utf8.nextCodepoint()) |_| {
        distict_chars += 1;
    }
    return distict_chars;
}
