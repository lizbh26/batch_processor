const std = @import("std");
const zeit = @import("zeit");

const Arena = std.heap.ArenaAllocator;

const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const Window = vaxis.Window;

const Label = @import("../../components/label.zig").LabelWidget;
const TimerWidget = @import("timer.zig").TimerWidget;

const Process = @import("~").models.Process.Process;
const usize_to = @import("~").utils.usize_to;

pub const Header = struct {
    arena: Arena,

    title: Label,
    timerWidget: TimerWidget,

    pub fn init(alloc: std.mem.Allocator, now: zeit.Instant) !*Header {
        const self = try alloc.create(Header);
        errdefer alloc.destroy(self);

        self.arena = Arena.init(alloc);

        try self.title.init(alloc);
        try self.timerWidget.init(self.arena.allocator(), now);

        return self;
    }

    pub fn deinit(self: *Header, alloc: std.mem.Allocator) void {
        self.arena.deinit();
        alloc.destroy(self);
    }

    pub fn tick(self: *Header, now: zeit.Instant) !void {
        try self.timerWidget.tick(now);
    }

    pub fn draw(self: *Header, win: Window) !void {
        const titleWidth = usize_to(u16, self.title.getWidth());
        const titleChild = win.child(.{ .x_off = @divTrunc(win.width - titleWidth, 2), .y_off = 0, .width = titleWidth, .height = 1 });
        self.title.draw(titleChild);

        const timerWidth = self.timerWidget.getWidth();
        const timerChild = win.child(.{ .x_off = win.width - timerWidth - 2, .y_off = 0, .width = timerWidth, .height = 1 });
        try self.timerWidget.draw(timerChild);
    }
};
