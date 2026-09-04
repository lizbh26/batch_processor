const std = @import("std");
const zeit = @import("zeit");

const Arena = std.heap.ArenaAllocator;

const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const Window = vaxis.Window;

const TimerWidget = @import("timer.zig").TimerWidget;

const Process = @import("~").models.Process.Process;
const usize_to = @import("~").utils.usize_to;

pub const Header = struct {
    arena: Arena,
    timerWidget: *TimerWidget,

    pub fn init(alloc: std.mem.Allocator, io: std.Io) !*Header {
        const self = try alloc.create(Header);
        errdefer alloc.destroy(self);

        self.arena = Arena.init(alloc);

        self.timerWidget = try TimerWidget.init(self.arena.allocator(), io);

        return self;
    }

    pub fn deinit(self: *Header, alloc: std.mem.Allocator) void {
        self.timerWidget.deinit(alloc);
        self.arena.deinit();
        alloc.destroy(self);
    }

    pub fn tick(self: *Header, now: zeit.Instant) void {
        self.timerWidget.tick(now);
    }

    pub fn draw(self: *Header, win: Window) !void {
        const timerWidth = self.timerWidget.getWidth();
        const timerChild = win.child(.{ .x_off = win.width - timerWidth - 2, .y_off = 0, .width = timerWidth, .height = 1 });
        try self.timerWidget.draw(timerChild);
    }
};
