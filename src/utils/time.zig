const std = @import("std");
const zeit = @import("zeit");

const leftpad = @import("leftpad.zig").leftpad;

pub fn milliseconds_to_time(ms: i128) zeit.Time {
    return zeit.instant(.{ .unix_nano = ms * 1000000 }, &zeit.utc).time();
}

pub fn time_to_string(alloc: std.mem.Allocator, diff: zeit.Time) ![]const u8 {
    //IMPORTANT: if simulation goes beyond a day, this will loop back around.
    var localArena = std.heap.ArenaAllocator.init(alloc);
    defer localArena.deinit();
    const localAlloc = localArena.allocator();

    const hours = if (diff.hour > 0) try std.fmt.allocPrint(localAlloc, "{d}:", .{diff.hour}) else "";

    var minutes: []const u8 = "";
    if (diff.minute > 0) {
        minutes = try std.fmt.allocPrint(localAlloc, "{d}:", .{diff.minute});
        if (minutes.len == 2)
            minutes = leftpad(minutes, 1, '0', localAlloc);
    }

    var seconds: []const u8 = try std.fmt.allocPrint(localAlloc, "{d}.", .{diff.second});
    if (diff.second < 10)
        seconds = leftpad(seconds, 1, '0', localAlloc);

    var milliseconds: []const u8 = try std.fmt.allocPrint(localAlloc, "{d}", .{diff.millisecond});
    if (milliseconds.len < 3)
        milliseconds = leftpad(milliseconds, 3 - milliseconds.len, '0', localAlloc);

    return try std.mem.concat(alloc, u8, &.{ hours, minutes, seconds, milliseconds });
}
