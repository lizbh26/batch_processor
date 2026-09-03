const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Process = @import("~").models.Process.Process;

const Window = vaxis.Window;
const TextView = vaxis.widgets.TextView;

const usize_to = @import("~").utils.usize_to;

const MAX_CARD_SIZE = 30;
const LabelWidget = struct {
    alloc: std.mem.Allocator,

    view: TextView,
    buffer: TextView.Buffer,

    pub fn init(alloc: std.mem.Allocator) !*LabelWidget {
        const self = try alloc.create(LabelWidget);
        self.alloc = alloc;
        self.view = .{};
        self.buffer = TextView.Buffer{};
        return self;
    }

    pub fn deinit(self: *LabelWidget) void {
        self.buffer.deinit(self.alloc);
        self.alloc.destroy(self);
    }

    pub fn changeText(self: *LabelWidget, newText: []const u8) !void {
        //TODO: only change text if it has changed from prev state
        self.buffer.clear(self.alloc);
        try self.buffer.append(self.alloc, .{ .bytes = newText });
    }

    pub fn draw(self: *LabelWidget, win: Window) void {
        self.view.draw(win, self.buffer);
    }
};

pub const ProcessCard = struct {
    ptr: *Process,

    idLabel: *LabelWidget,
    opLabel: *LabelWidget,
    timeLabel: *LabelWidget,

    pub fn init(alloc: std.mem.Allocator, process: *Process) !*ProcessCard {
        const self = try alloc.create(ProcessCard);
        errdefer alloc.destroy(self);

        try self.kickstart(alloc);
        try self.updateProcess(alloc, process);

        return self;
    }

    pub fn kickstart(self: *ProcessCard, alloc: std.mem.Allocator) !void {
        self.idLabel = try LabelWidget.init(alloc);
        errdefer self.idLabel.deinit();

        self.opLabel = try LabelWidget.init(alloc);
        errdefer self.opLabel.deinit();

        self.timeLabel = try LabelWidget.init(alloc);
        errdefer self.timeLabel.deinit();
    }

    pub fn deinit(self: *ProcessCard, alloc: std.mem.Allocator) void {
        self.idLabel.deinit(alloc);
        self.opLabel.deinit(alloc);
        self.timeLabel.deinit(alloc);
        alloc.destroy(self);
    }

    pub fn updateProcess(self: *ProcessCard, alloc: std.mem.Allocator, ptr: *Process) !void {
        self.ptr = ptr;
        try self.idLabel.changeText(try std.mem.concat(alloc, u8, &.{ "ID: ", self.ptr.id }));
        try self.opLabel.changeText(try std.mem.concat(alloc, u8, &.{ "OP: ", try self.ptr.operation.toString(alloc) }));
        try self.timeLabel.changeText(try std.fmt.allocPrint(alloc, "TME: {d}  TT: {d}  TR: {d}", .{ self.ptr.tme, 0, self.ptr.tme }));
    }

    pub fn draw(self: *ProcessCard, win: Window) void {
        const container = win.child(.{ .x_off = 1, .y_off = 0, .width = @min(win.width - 2, MAX_CARD_SIZE), .height = 5, .border = .{ .where = .all, .style = .{ .fg = .{ .index = 255 } } } });

        for (&[_]*LabelWidget{ self.idLabel, self.opLabel, self.timeLabel }, 0..) |*label, i| {
            const child = container.child(.{ .x_off = 1, .y_off = usize_to(i17, i), .width = container.width - 2, .height = 1 });
            label.*.draw(child);
        }
    }
};
