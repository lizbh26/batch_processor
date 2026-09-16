const std = @import("std");
const zeit = @import("zeit");

const Arena = std.heap.ArenaAllocator;

const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const Window = vaxis.Window;

const Label = @import("../../components/label.zig").LabelWidget;
const TimerWidget = @import("timer.zig").TimerWidget;

const Process = @import("~").models.Process.Process;
const ExecutionContext = @import("~").models.Context.ExecutionContext;

const usize_to = @import("~").utils.usize_to;

pub const Header = struct {
    arena: Arena,

    timerWidget: TimerWidget,

    pub fn init(self: *Header, extern_alloc: std.mem.Allocator, ctx: *ExecutionContext) void {
        self.arena = Arena.init(extern_alloc);
        const alloc = self.arena.allocator();

        self.timerWidget.init(alloc, ctx);
    }

    pub fn deinit(self: *Header, alloc: std.mem.Allocator) void {
        self.arena.deinit();
        alloc.destroy(self);
    }

    pub fn draw(self: *Header, win: Window) !void {
        const timerWidth = self.timerWidget.getWidth();
        const timerChild = win.child(.{ .x_off = @divTrunc(win.width - timerWidth, 2), .y_off = 0, .width = timerWidth, .height = 1 });
        try self.timerWidget.draw(timerChild);
    }
};
