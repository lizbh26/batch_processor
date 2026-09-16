const std = @import("std");
const zeit = @import("zeit");

const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const Window = vaxis.Window;
const LabelWidget = @import("../../components/label.zig").LabelWidget;

const Process = @import("~").models.Process.Process;
const ExecutionContext = @import("~").models.Context.ExecutionContext;

const usize_to = @import("~").utils.usize_to;
const time_to_string = @import("~").utils.time_to_string;

pub const TimerWidget = struct {
    alloc: std.mem.Allocator,
    ctx: *ExecutionContext,

    label: LabelWidget,

    pub fn init(self: *TimerWidget, alloc: std.mem.Allocator, ctx: *ExecutionContext) void {
        self.alloc = alloc;
        self.label.init(alloc);
        self.ctx = ctx;
    }

    pub fn deinit(self: *TimerWidget, alloc: std.mem.Allocator) void {
        self.label.deinit();
        alloc.destroy(self);
    }

    pub fn getWidth(self: *TimerWidget) u16 {
        return usize_to(u16, self.label.getWidth());
    }
    pub fn draw(self: *TimerWidget, win: Window) !void {
        const diff = zeit.instant(.{ .unix_nano = self.ctx.time_ellapsed_nano }, &zeit.utc).time();
        try self.label.changeText(try time_to_string(self.alloc, diff));
        self.label.draw(win);
    }
};
