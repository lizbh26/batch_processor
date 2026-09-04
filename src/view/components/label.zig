const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;
const TextView = vaxis.widgets.TextView;

const count_utf8 = @import("~").utils.count_utf8;

pub const LabelWidget = struct {
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

    pub fn getText(self: *LabelWidget) []const u8 {
        return self.buffer.content.items;
    }
    pub fn getWidth(self: *LabelWidget) usize {
        return count_utf8(self.getText()) + 1;
    }

    pub fn changeText(self: *LabelWidget, newText: []const u8) !void {
        if (std.mem.eql(u8, self.getText(), newText)) return;

        self.buffer.clear(self.alloc);
        try self.buffer.append(self.alloc, .{ .bytes = newText });
    }

    pub fn draw(self: *LabelWidget, win: Window) void {
        self.view.draw(win, self.buffer);
    }
};
