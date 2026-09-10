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
    ellapsed: i128,

    label: LabelWidget,

    running: bool,

    pub fn init(self: *TimerWidget, alloc: std.mem.Allocator) void {
        self.alloc = alloc;

        self.label.init(alloc);

        self.start = undefined;
        self.ellapsed = 0;
        self.running = false;
    }

    pub fn deinit(self: *TimerWidget, alloc: std.mem.Allocator) void {
        self.label.deinit();
        alloc.destroy(self);
    }

    pub fn kickstart(self: *TimerWidget, now: zeit.Instant) void {
        self.start = now;
        self.running = true;
    }

    pub fn stop(self: *TimerWidget) void {
        self.running = false;
    }

    pub fn tick(self: *TimerWidget, now: zeit.Instant) !void {
        self.running = true;

        const diffNano = now.timestamp - self.start.timestamp;
        self.ellapsed += diffNano;

        const diff = zeit.instant(.{ .unix_nano = self.ellapsed }, &zeit.utc).time();
        try self.label.changeText(try self.diffToString(diff));

        self.start = now;
    }

    pub fn getWidth(self: *TimerWidget) u16 {
        return usize_to(u16, self.label.getWidth());
    }
    pub fn draw(self: *TimerWidget, win: Window) !void {
        self.label.draw(win);
    }

    fn diffToString(self: *TimerWidget, diff: zeit.Time) ![]const u8 {
        //IMPORTANT: if simulation goes beyond a day, this will loop back around.
        var localArena = std.heap.ArenaAllocator.init(self.alloc);
        defer localArena.deinit();
        const localAlloc = localArena.allocator();

        const hours = if (diff.hour > 0) try std.fmt.allocPrint(localAlloc, "{d}:", .{diff.hour}) else "";

        var minutes: []const u8 = try std.fmt.allocPrint(self.alloc, "{d}:", .{diff.minute});
        if (minutes.len == 2)
            minutes = leftpad(minutes, 1, '0', self.alloc);

        var seconds: []const u8 = try std.fmt.allocPrint(self.alloc, "{d}.", .{diff.second});
        if (seconds.len == 2)
            seconds = leftpad(seconds, 1, '0', self.alloc);

        var milliseconds: []const u8 = try std.fmt.allocPrint(self.alloc, "{d}", .{diff.millisecond});
        if (milliseconds.len < 3)
            milliseconds = leftpad(milliseconds, 3 - milliseconds.len, '0', self.alloc);

        return try std.mem.concat(self.alloc, u8, &.{ hours, minutes, seconds, milliseconds });
    }
};
