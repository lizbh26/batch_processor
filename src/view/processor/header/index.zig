const std = @import("std");
const zeit = @import("zeit");

const Arena = std.heap.ArenaAllocator;

const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const Window = vaxis.Window;

const ClockWidget = @import("global_clock.zig").ClockWidget;

const Process = @import("~").models.Process.Process;
const usize_to = @import("~").utils.usize_to;

pub const Header = struct {
    arena: Arena,
    clockWidget: *ClockWidget,

    pub fn init(alloc: std.mem.Allocator, io: std.Io) !*Header {
        const self = try alloc.create(Header);
        errdefer alloc.destroy(self);

        self.arena = Arena.init(alloc);

        self.clockWidget = try ClockWidget.init(self.arena.allocator(), io);

        return self;
    }

    pub fn tick(self: *Header, now: zeit.Instant) !void {
        try self.clockWidget.tick(now);
    }

    pub fn draw(self: *Header, win: Window) !void {
        const clockWidth = self.clockWidget.getWidth();
        const clockChild = win.child(.{ .x_off = win.width - clockWidth - 2, .y_off = 0, .width = clockWidth, .height = 1 });
        self.clockWidget.draw(clockChild);
    }
};
