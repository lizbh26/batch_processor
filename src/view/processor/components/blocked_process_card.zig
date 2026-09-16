const std = @import("std");

const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const Window = vaxis.Window;
const LabelWidget = @import("../../components/label.zig").LabelWidget;

const Process = @import("~").models.Process;

const usize_to = @import("~").utils.usize_to;

const MAX_CARD_WIDTH = 50;
const PADDING_X_INNER = 1;

pub const BlockedProcessCard = struct {
    const Self = @This();

    arena: std.heap.ArenaAllocator,

    blocked_process: ?*Process.BlockedProcess,

    idLabel: LabelWidget,
    timeLabel: LabelWidget,

    pub fn init(self: *Self, extern_alloc: std.mem.Allocator) void {
        self.arena = std.heap.ArenaAllocator.init(extern_alloc);
        const alloc = self.arena.allocator();

        self.idLabel.init(alloc);

        self.timeLabel.init(alloc);
        self.blocked_process = null;
    }

    pub fn deinit(self: *Self) void {
        self.arena.deinit();
    }

    pub fn updateBlockedProcess(self: *Self, bp: *Process.BlockedProcess) !void {
        const alloc = self.arena.allocator();
        self.blocked_process = bp;

        try self.idLabel.changeText(try std.fmt.allocPrint(alloc, "ID: {d}", .{bp.p.id}));
        const time_taken = @divTrunc(bp.ellapsed_ms, 1000);
        try self.timeLabel.changeText(try std.fmt.allocPrint(alloc, "Tiempo bloqueado: {d}", .{time_taken}));
    }

    pub fn getWidth(_: Self, win: Window) u16 {
        return @min(win.width, MAX_CARD_WIDTH);
    }
    pub fn getHeight(_: Self) u16 {
        return 4;
    }

    pub fn draw(self: *Self, win: Window) void {
        if (self.blocked_process == null) return;

        const container = win.child(.{ .x_off = 0, .y_off = 0, .width = self.getWidth(win), .height = self.getHeight(), .border = .{ .where = .all, .style = .{ .fg = .{ .index = 255 } } } });

        const idLabelWidth = container.width - PADDING_X_INNER * 2;
        const idChild = container.child(.{ .x_off = PADDING_X_INNER, .y_off = 0, .width = idLabelWidth, .height = 1 });
        self.idLabel.draw(idChild);

        const child = container.child(.{ .x_off = PADDING_X_INNER, .y_off = 1, .width = container.width - PADDING_X_INNER * 2, .height = 1 });
        self.timeLabel.draw(child);
    }
};
