const std = @import("std");
const zeit = @import("zeit");

const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const Window = vaxis.Window;
const LabelWidget = @import("../../components/label.zig").LabelWidget;

const Process = @import("~").models.Process.Process;

const usize_to = @import("~").utils.usize_to;
const leftpad = @import("~").utils.leftpad;

pub const TimerWidget = struct {
    alloc: std.mem.Allocator,

    start: zeit.Instant,
    diff: zeit.Time,
    label: *LabelWidget,

    pub fn init(alloc: std.mem.Allocator, io: std.Io) !*TimerWidget {
        const self = try alloc.create(TimerWidget);
        self.start = zeit.instant(.{ .now = io }, &zeit.utc);
        self.diff = .{};

        self.alloc = alloc;
        self.label = try LabelWidget.init(alloc);

        return self;
    }

    pub fn deinit(self: *TimerWidget, alloc: std.mem.Allocator) void {
        self.label.deinit();
        alloc.destroy(self);
    }

    pub fn tick(self: *TimerWidget, now: zeit.Instant) void {
        const diffNano = now.timestamp - self.start.timestamp;
        self.diff = zeit.instant(.{ .unix_nano = diffNano }, &zeit.utc).time();
    }

    pub fn getWidth(self: *TimerWidget) u16 {
        return usize_to(u16, self.label.getWidth());
    }
    pub fn draw(self: *TimerWidget, win: Window) !void {
        //IMPORTANT: if simulation goes beyond a day, this will loop back around.
        const hours = if (self.diff.hour > 0) try std.fmt.allocPrint(self.alloc, "{d}:", .{self.diff.hour}) else "";
        defer self.alloc.free(hours);

        var minutes: []const u8 = try std.fmt.allocPrint(self.alloc, "{d}:", .{self.diff.minute});
        if (minutes.len == 2) minutes = leftpad(minutes, 1, '0', self.alloc);
        defer self.alloc.free(minutes);

        var seconds: []const u8 = try std.fmt.allocPrint(self.alloc, "{d}.", .{self.diff.second});
        if (seconds.len == 2) seconds = leftpad(seconds, 1, '0', self.alloc);
        defer self.alloc.free(seconds);

        var milliseconds: []const u8 = try std.fmt.allocPrint(self.alloc, "{d}", .{self.diff.millisecond});
        if (milliseconds.len < 3) milliseconds = leftpad(milliseconds, 3 - milliseconds.len, '0', self.alloc);
        defer self.alloc.free(seconds);

        try self.label.changeText(try std.mem.concat(self.alloc, u8, &.{ hours, minutes, seconds, milliseconds }));
        self.label.draw(win);
    }
};
