const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;
const TextView = vaxis.widgets.TextView;

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

    pub fn changeText(self: *LabelWidget, newText: []const u8) !void {
        //TODO: only change text if it has changed from prev state
        self.buffer.clear(self.alloc);
        try self.buffer.append(self.alloc, .{ .bytes = newText });
    }

    pub fn draw(self: *LabelWidget, win: Window) void {
        self.view.draw(win, self.buffer);
    }
};
