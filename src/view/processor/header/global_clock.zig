const std = @import("std");
const zeit = @import("zeit");

const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const Window = vaxis.Window;
const LabelWidget = @import("../../components/label.zig").LabelWidget;

const Process = @import("~").models.Process.Process;

const usize_to = @import("~").utils.usize_to;
const leftpad = @import("~").utils.leftpad;

pub const ClockWidget = struct {
    alloc: std.mem.Allocator,

    start: zeit.Instant,
    label: *LabelWidget,

    pub fn init(alloc: std.mem.Allocator, io: std.Io) !*ClockWidget {
        const self = try alloc.create(ClockWidget);
        self.start = zeit.instant(.{ .now = io }, &zeit.utc);

        self.alloc = alloc;
        self.label = try LabelWidget.init(alloc);

        return self;
    }

    pub fn tick(self: *ClockWidget, now: zeit.Instant) !void {
        const diffNano = now.timestamp - self.start.timestamp;
        const diff = zeit.instant(.{ .unix_nano = diffNano }, &zeit.utc).time();

        //IMPORTANT: if simulation goes beyond a day, this will loop back around.

        const hours = if (diff.hour > 0) try std.fmt.allocPrint(self.alloc, "{d}:", .{diff.hour}) else "";
        defer self.alloc.free(hours);

        var minutes: []const u8 = try std.fmt.allocPrint(self.alloc, "{d}:", .{diff.minute});
        if (minutes.len == 2) minutes = leftpad(minutes, 1, '0', self.alloc);
        defer self.alloc.free(minutes);

        var seconds: []const u8 = try std.fmt.allocPrint(self.alloc, "{d}", .{diff.second});
        if (seconds.len == 1) seconds = leftpad(seconds, 1, '0', self.alloc);
        defer self.alloc.free(seconds);

        try self.label.changeText(try std.mem.concat(self.alloc, u8, &.{ hours, minutes, seconds }));
    }

    pub fn getWidth(self: *ClockWidget) u16 {
        return usize_to(u16, self.label.getText().len + 1);
    }
    pub fn draw(self: *ClockWidget, win: Window) void {
        self.label.draw(win);
    }
};
