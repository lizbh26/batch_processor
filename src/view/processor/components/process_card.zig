const std = @import("std");

const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const Window = vaxis.Window;
const LabelWidget = @import("../../components/label.zig").LabelWidget;

const Process = @import("~").models.Process.Process;

const usize_to = @import("~").utils.usize_to;

const MAX_CARD_WIDTH = 40;
pub const ProcessCard = struct {
    process: ?*Process,

    idLabel: *LabelWidget,
    batchLabel: *LabelWidget,
    opLabel: *LabelWidget,
    timeLabel: *LabelWidget,

    pub fn init(alloc: std.mem.Allocator) !*ProcessCard {
        const self = try alloc.create(ProcessCard);
        errdefer alloc.destroy(self);

        try self.kickstart(alloc);
        self.process = null;

        return self;
    }

    pub fn kickstart(self: *ProcessCard, alloc: std.mem.Allocator) !void {
        self.idLabel = try LabelWidget.init(alloc);
        errdefer self.idLabel.deinit();

        self.batchLabel = try LabelWidget.init(alloc);
        errdefer self.batchLabel.deinit();

        self.opLabel = try LabelWidget.init(alloc);
        errdefer self.opLabel.deinit();

        self.timeLabel = try LabelWidget.init(alloc);
        errdefer self.timeLabel.deinit();
    }

    pub fn deinit(self: *ProcessCard, alloc: std.mem.Allocator) void {
        self.idLabel.deinit();
        self.batchLabel.deinit();
        self.opLabel.deinit();
        self.timeLabel.deinit();
        alloc.destroy(self);
    }

    pub fn updateProcess(self: *ProcessCard, alloc: std.mem.Allocator, process: *Process, batchIdx: usize) !void {
        self.process = process;

        try self.idLabel.changeText(try std.mem.concat(alloc, u8, &.{ "ID: ", process.id }));
        try self.batchLabel.changeText(try std.fmt.allocPrint(alloc, " Lote {d} ", .{batchIdx}));
        try self.opLabel.changeText(try std.mem.concat(alloc, u8, &.{ "OP: ", try process.operation.toString(alloc, process.isDone()) }));
        try self.timeLabel.changeText(try std.fmt.allocPrint(alloc, "TME: {d}  TT: {d}  TR: {d}", .{ process.tme, 0, process.tme }));
    }

    pub fn draw(self: *ProcessCard, win: Window) void {
        if (self.process == null) return;

        const container = win.child(.{ .x_off = 1, .y_off = 0, .width = @min(win.width - 2, MAX_CARD_WIDTH), .height = 5, .border = .{ .where = .all, .style = .{ .fg = .{ .index = 255 } } } });

        const batchLabelWidth = usize_to(u16, self.batchLabel.getText().len) + 1;
        const idLabelWidth = container.width - batchLabelWidth - 2;

        const idChild = container.child(.{ .x_off = 1, .y_off = 0, .width = idLabelWidth, .height = 1 });
        self.idLabel.draw(idChild);

        const batchChild = container.child(.{ .x_off = idLabelWidth + 1, .y_off = 0, .width = batchLabelWidth, .height = 1 });
        self.batchLabel.draw(batchChild);

        for (&[_]*LabelWidget{ self.opLabel, self.timeLabel }, 0..) |*label, i| {
            const child = container.child(.{ .x_off = 1, .y_off = 1 + usize_to(i17, i), .width = container.width - 2, .height = 1 });
            label.*.draw(child);
        }
    }
};
