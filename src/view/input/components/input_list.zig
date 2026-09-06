const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;
const Key = vaxis.Key;

const count_utf8 = @import("~").utils.count_utf8;
const usize_to = @import("~").utils.usize_to;

const Input = @import("input.zig");
const Label = @import("../../components/label.zig").LabelWidget;

pub const WidgetConfig = struct { alloc: std.mem.Allocator, inputs: []const Input.WidgetConfig };

fn findLargestLabelSize(arr: []const Input.WidgetConfig) u16 {
    var largest: usize = 0;
    for (arr) |config| {
        largest = @max(largest, count_utf8(config.label));
    }

    return usize_to(u16, largest);
}

const PADDING_X = 5;
const PADDING_Y = 2;

pub const InputListWidget = struct {
    arena: std.heap.ArenaAllocator,

    inputs: []Input.InputWidget,
    active_field_idx: usize,

    title: Label,
    maxRuntimeWidth: u16,

    pub fn init(self: *InputListWidget, config: *const WidgetConfig) void {
        self.arena = std.heap.ArenaAllocator.init(config.alloc);
        const alloc = self.arena.allocator();

        self.inputs = alloc.alloc(Input.InputWidget, config.inputs.len) catch unreachable;
        const largestLabelSize = findLargestLabelSize(config.inputs);

        for (config.inputs, 0..) |inputConfig, i| {
            self.inputs[i].init(alloc, largestLabelSize, inputConfig);
        }

        self.maxRuntimeWidth = 0;
        self.title.init(alloc);

        self.active_field_idx = 0;
        self.getActiveInput().focus();
    }
    pub fn deinit(self: *InputListWidget, alloc: std.mem.Allocator) void {
        for (self.inputs) |input| {
            input.deinit(alloc);
        }
        alloc.free(self.inputs);
    }

    pub fn reset(self: *InputListWidget) void {
        for (self.inputs) |*input| {
            input.reset();
        }
        self.active_field_idx = 0;
    }

    pub fn isDone(self: *InputListWidget) bool {
        return self.active_field_idx == self.inputs.len;
    }

    pub fn getInputAt(self: *InputListWidget, idx: usize) []const u8 {
        if (idx > self.inputs.len) return "";
        return self.inputs[idx].getInputText(self.arena.allocator());
    }
    pub fn getActiveInput(self: *InputListWidget) *Input.InputWidget {
        return &self.inputs[self.active_field_idx];
    }

    pub fn handleInput(self: *InputListWidget, key: Key) !void {
        if (self.isDone()) return;

        const originalInput = self.getActiveInput();

        if (key.matchesAny(&.{ Key.tab, Key.left_alt, Key.right_alt }, .{})) {
            return;
        }

        if (key.codepoint == Key.enter) {
            if (originalInput.isValid())
                self.active_field_idx += 1;
            if (self.isDone()) return;
        } else if (key.codepoint == Key.backspace and originalInput.isEmpty()) {
            if (self.active_field_idx > 0) {
                self.active_field_idx -= 1;
            }
        } else {
            try self.getActiveInput().handleInput(key);
        }

        originalInput.unfocus();
        self.getActiveInput().focus();
    }

    pub fn draw(self: *InputListWidget, win: Window) !void {
        const width, const height = self.getDimensions(win);

        const container = win.child(.{ .x_off = @divTrunc(win.width - width, 2), .y_off = @divTrunc(win.height - height, 2), .width = width, .height = height, .border = .{ .where = .all, .style = .{ .fg = .{ .index = 255 } } } });

        const titleWidth = usize_to(u16, self.title.getWidth());
        const titleChild = container.child(.{ .x_off = @divTrunc(container.width - titleWidth, 2), .y_off = 1, .width = titleWidth, .height = 1 });
        self.title.draw(titleChild);

        var activeChildWindow: Window = undefined;

        var y_offset: i17 = PADDING_Y + 2;
        for (0..self.inputs.len) |i| {
            const input = &self.inputs[i];

            const child = container.child(.{ .x_off = PADDING_X, .y_off = y_offset, .width = win.width - 2, .height = input.getHeight() });
            y_offset += input.getHeight() + 1;

            if (i == self.active_field_idx) {
                activeChildWindow = child;
                continue;
            }

            try input.draw(child);
        }
        try self.getActiveInput().draw(activeChildWindow);
    }

    fn getDimensions(self: *InputListWidget, win: Window) struct { u16, u16 } {
        var w: u16 = 0;
        var h: u16 = 0;

        for (self.inputs) |*input| {
            w = @max(input.getWidth(), w);
            h += input.getHeight() + 1;
        }
        w += PADDING_X * 2 + 2;
        h += PADDING_Y * 2 + 2;

        self.maxRuntimeWidth = @min(@max(self.maxRuntimeWidth, w), win.width);
        h = @min(h, win.height);

        return .{ self.maxRuntimeWidth, h };
    }
};
