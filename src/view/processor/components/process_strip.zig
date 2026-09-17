const std = @import("std");
const vaxis = @import("vaxis");
const zeit = @import("zeit");

const Arena = std.heap.ArenaAllocator;

const models = @import("~").models;
const ExecutionContext = models.Context.ExecutionContext;
const Process = models.Process;

const Window = vaxis.Window;
const Label = @import("../../components/label.zig").LabelWidget;

const usize_to = @import("~").utils.usize_to;
const time = @import("~").utils.time;

const MAX_OP_PADDED_WIDTH = 40;

pub const ProcessStripWidget = struct {
    const Self = @This();

    arena: std.heap.ArenaAllocator,

    idLabel: Label,
    opLabel: Label,
    timeLabel: Label,

    show: bool,

    pub fn init(self: *Self, extern_alloc: std.mem.Allocator) void {
        self.arena = std.heap.ArenaAllocator.init(extern_alloc);
        const alloc = self.arena.allocator();

        self.idLabel.init(alloc);
        self.opLabel.init(alloc);
        self.timeLabel.init(alloc);
        self.show = false;
    }
    pub fn deinit(self: *Self) void {
        self.arena.deinit();
    }

    pub fn hide(self: *Self) void {
        self.show = false;
    }

    pub fn update(self: *Self, p: *Process.Process, stage: Process.ProcessStage) !void {
        self.show = true;
        const alloc = self.arena.allocator();

        try self.idLabel.changeText(try std.fmt.allocPrint(alloc, "ID: {s}    {s}  ", .{ p.id, Process.processStageToString(stage) }));
        try self.opLabel.changeText(try std.fmt.allocPrint(alloc, "  OP: {s}  ", .{if (stage == .new) "NULO" else try p.operation.toString(alloc, stage == .finalized)}));

        if (stage != .new) {
            const arrival_time = try time.time_to_string(alloc, time.milliseconds_to_time(p.arrival_time_ms));
            const response_time = if (p.response_time_ms) |rt| try time.time_to_string(alloc, time.milliseconds_to_time(rt)) else "N/A";
            const service_time = try time.time_to_string(alloc, time.milliseconds_to_time(p.service_time_ms));

            const return_time_ms = p.getReturnTimeMs() catch 0;
            const return_time = if (return_time_ms == 0) "N/A" else try time.time_to_string(alloc, time.milliseconds_to_time(return_time_ms));

            const wait_time_ms = p.getReturnTimeMs() catch 0;
            const wait_time = if (return_time_ms == 0) "N/A" else try time.time_to_string(alloc, time.milliseconds_to_time(wait_time_ms));

            const finalization_time = if (p.finalization_time_ms == 0) "N/A" else try time.time_to_string(alloc, time.milliseconds_to_time(p.finalization_time_ms));

            try self.timeLabel.changeText(try std.fmt.allocPrint(alloc, "  Llegada: {s}  Respuesta: {s}  Servicio: {s}  Espera: {s}  Retorno: {s}  Finalización: {s}  ", .{ arrival_time, response_time, service_time, wait_time, return_time, finalization_time }));
        } else {
            try self.timeLabel.changeText("");
        }
    }

    pub fn getDimensions(self: *Self, win: Window) struct { id: u16, op: u16, time: u16, total: u16, rows: u16 } {
        const timeWidth = @min(usize_to(u16, self.timeLabel.getWidth()), win.width);
        const idWidth = @min(usize_to(u16, self.idLabel.getWidth()), win.width);

        const remaining = if (win.width - timeWidth > idWidth) win.width - timeWidth - idWidth else 0;
        const opWidth = @max(@min(usize_to(u16, self.opLabel.getWidth()), win.width), @min(MAX_OP_PADDED_WIDTH, remaining));

        var totalWidth = idWidth + opWidth;
        var rows: u16 = 1;

        if (totalWidth > win.width) {
            totalWidth = @max(idWidth, opWidth, timeWidth);
            rows = 3;
        } else if (totalWidth + timeWidth > win.width) {
            totalWidth = @max(totalWidth, timeWidth);
            rows = 2;
        } else {
            totalWidth += timeWidth;
        }

        return .{ .id = idWidth, .op = opWidth, .time = timeWidth, .total = totalWidth, .rows = rows };
    }
    pub fn draw(self: *Self, win: Window) void {
        if (!self.show) return;

        const dim = self.getDimensions(win);

        const container = win.child(.{ .x_off = @divFloor(win.width - dim.total, 2), .width = @min(dim.total, win.width), .height = dim.rows + 1, .border = .{ .where = .bottom, .style = .{ .fg = .{ .index = 255 } } } });

        const idChild = container.child(.{ .width = dim.id });
        self.idLabel.draw(idChild);

        const opChild = container.child(.{ .x_off = if (dim.rows == 3) 0 else dim.id, .y_off = if (dim.rows == 3) 1 else 0, .width = dim.op });
        self.opLabel.draw(opChild);

        const timeChild = container.child(.{ .x_off = if (dim.rows > 1) 0 else dim.id + dim.op, .y_off = dim.rows - 1, .width = dim.time });
        self.timeLabel.draw(timeChild);
    }
};
