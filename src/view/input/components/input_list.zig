const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;

const usize_to = @import("~").utils.usize_to;

const Input = @import("input_with_label.zig");

pub const WidgetConfig = struct { alloc: std.mem.Allocator, maxLabelSize: u16, inputs: []const Input.WidgetConfig };

pub const InputListWidget = struct {
    arena: std.heap.ArenaAllocator,

    inputs: []Input.InputWidget,
    active_field_idx: usize,

    pub fn init(self: *InputListWidget, config: *const WidgetConfig) !void {
        self.arena = std.heap.ArenaAllocator.init(config.alloc);
        const alloc = self.arena.allocator();

        self.inputs = try alloc.alloc(Input.InputWidget, config.inputs.len);
        for (config.inputs, 0..) |inputConfig, i| {
            try self.inputs[i].init(alloc, config.maxLabelSize, inputConfig);
        }

        self.active_field_idx = 0;
    }
    pub fn deinit(self: *InputListWidget, alloc: std.mem.Allocator) void {
        for (self.inputs) |input| {
            input.deinit(alloc);
        }
        alloc.free(self.inputs);
    }

    pub fn isDone(self: *InputListWidget) bool {
        return self.active_field_idx == self.inputs.len;
    }

    pub fn getInputAt(self: *InputListWidget, idx: usize) []const u8 {
        if (idx > self.inputs.len) return "";
        return self.inputs[idx].getInputText();
    }
    pub fn getActiveInput(self: *InputListWidget) *Input.InputWidget {
        return &self.inputs[self.active_field_idx];
    }

    pub fn handleInput(self: *InputListWidget, key: vaxis.Key) !void {
        if (self.isDone()) return;

        const input = self.getActiveInput();
        input.unfocus();

        if (key.matches(vaxis.Key.delete, .{}) and input.isEmpty()) {
            if (self.active_field_idx > 0) self.active_field_idx -= 1;
        } else if (key.matches(vaxis.Key.enter, .{}) and input.isValid()) {
            self.active_field_idx += 1;
        } else {
            try self.inputs[self.active_field_idx].handle_input(key);
        }
        self.getActiveInput().focus();
    }

    pub fn draw(self: *InputListWidget, win: Window) !void {
        for (self.inputs, 0..) |*input, i| {
            const y_offset = usize_to(u16, Input.TOTAL_HEIGHT * i);

            const child = win.child(.{ .x_off = 1, .y_off = @intCast(y_offset), .width = win.width - 2, .height = Input.TOTAL_HEIGHT });
            try input.draw(child);
        }
    }
};
