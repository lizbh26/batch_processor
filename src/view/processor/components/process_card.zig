const std = @import("std");

const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const Window = vaxis.Window;
const LabelWidget = @import("../../components/label.zig").LabelWidget;

const Process = @import("~").models.Process.Process;

const usize_to = @import("~").utils.usize_to;

const MAX_CARD_WIDTH = 40;
pub const CardType = enum { pending, doing, completed };
pub const ProcessCard = struct {
    process: ?*Process,
    type: CardType,

    idLabel: *LabelWidget,
    batchLabel: *LabelWidget,
    opLabel: *LabelWidget,
    timeLabel: *LabelWidget,

    pub fn init(alloc: std.mem.Allocator, cardType: CardType) !*ProcessCard {
        const self = try alloc.create(ProcessCard);
        errdefer alloc.destroy(self);

        self.type = cardType;

        try self.kickstart(alloc);
        self.process = null;

        return self;
    }

    pub fn kickstart(self: *ProcessCard, alloc: std.mem.Allocator) !void {
        try self.idLabel.init(alloc);
        errdefer self.idLabel.deinit();

        try self.batchLabel.init(alloc);
        errdefer self.batchLabel.deinit();

        try self.opLabel.init(alloc);
        errdefer self.opLabel.deinit();

        try self.timeLabel.init(alloc);
        errdefer self.timeLabel.deinit();
    }

    pub fn deinit(self: *ProcessCard, alloc: std.mem.Allocator) void {
        self.idLabel.deinit();
        self.batchLabel.deinit();
        self.opLabel.deinit();
        self.timeLabel.deinit();
        alloc.destroy(self);
    }

    pub fn updateProcess(self: *ProcessCard, alloc: std.mem.Allocator, process: *Process) !void {
        self.process = process;

        try self.idLabel.changeText(try std.mem.concat(alloc, u8, &.{ "ID: ", process.id }));
        try self.batchLabel.changeText(try std.fmt.allocPrint(alloc, " Lote {d} ", .{process.batchIdx + 1}));
        try self.opLabel.changeText(try std.mem.concat(alloc, u8, &.{ "OP: ", try process.operation.toString(alloc, process.isDone()) }));

        const time_estimated = @divTrunc(process.tme_ms, 1000);
        const time_taken = @divTrunc(process.tt_ms, 1000);
        const time_remaining = time_estimated - time_taken;
        try self.timeLabel.changeText(try std.fmt.allocPrint(alloc, "TME: {d}  TT: {d}  TR: {d}", .{ time_estimated, time_taken, time_remaining }));
    }

    pub fn getWidth(_: *ProcessCard) u16 {
        return MAX_CARD_WIDTH;
    }
    pub fn getHeight(self: *ProcessCard) u16 {
        if (self.type == .doing) return 5;
        return 4;
    }

    pub fn draw(self: *ProcessCard, win: Window) void {
        if (self.process == null) return;

        const container = win.child(.{ .x_off = 1, .y_off = 0, .width = @min(win.width - 2, MAX_CARD_WIDTH), .height = 5, .border = .{ .where = .all, .style = .{ .fg = .{ .index = 255 } } } });

        const batchLabelWidth = usize_to(u16, self.batchLabel.getWidth()) + 1;
        const idLabelWidth = container.width - batchLabelWidth - 2;

        const idChild = container.child(.{ .x_off = 1, .y_off = 0, .width = idLabelWidth, .height = 1 });
        self.idLabel.draw(idChild);

        const batchChild = container.child(.{ .x_off = idLabelWidth + 1, .y_off = 0, .width = batchLabelWidth, .height = 1 });
        self.batchLabel.draw(batchChild);

        var y_off: i17 = 1;
        if (self.type != .pending) {
            const child = container.child(.{ .x_off = 1, .y_off = y_off, .width = container.width - 2, .height = 1 });
            self.opLabel.draw(child);
            y_off += 1;
        }
        if (self.type != .completed) {
            const child = container.child(.{ .x_off = 1, .y_off = y_off, .width = container.width - 2, .height = 1 });
            self.timeLabel.draw(child);
        }
    }
};
