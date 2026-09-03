const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;

const usize_to = @import("~").utils.usize_to;

const Input = @import("input_with_label.zig");

pub const WidgetConfig = struct { alloc: std.mem.Allocator, maxLabelSize: u16, inputs: []const Input.WidgetConfig };

pub const InputListWidget = struct {
    inputs: []Input.Widget,
    confirmButton: vxfw.Button,
    active_field_idx: usize,

    isDone: bool,

    pub fn init(config: *const WidgetConfig) !*InputListWidget {
        const self = try config.alloc.create(InputListWidget);
        self.inputs = try config.alloc.alloc(Input.Widget, config.inputs.len);

        for (config.inputs, 0..) |inputConfig, i| {
            try self.inputs[i].setDefaults(config.alloc, config.maxLabelSize, inputConfig);
        }
        self.isDone = false;

        self.active_field_idx = 0;

        return self;
    }
    pub fn deinit(self: *InputListWidget, alloc: std.mem.Allocator) void {
        for (self.inputs) |input| {
            input.deinit(alloc);
        }
        alloc.free(self.inputs);
        alloc.destroy(self);
    }

    pub fn getInputAt(self: *InputListWidget, idx: usize) []const u8 {
        if (idx > self.inputs.len) return "";
        return self.inputs[idx].getInputText();
    }

    pub fn handle_input(self: *InputListWidget, key: vaxis.Key) !void {
        const NUMBER_OF_FIELDS = self.inputs.len;
        self.active_field_idx = @min(self.active_field_idx, NUMBER_OF_FIELDS - 1);

        self.inputs[self.active_field_idx].unfocus();
        if (key.matches(vaxis.Key.up, .{})) {
            self.active_field_idx = if (self.active_field_idx == 0) NUMBER_OF_FIELDS - 1 else self.active_field_idx - 1;
        } else if (key.matches(vaxis.Key.down, .{})) {
            self.active_field_idx = if (self.active_field_idx == NUMBER_OF_FIELDS - 1) 0 else self.active_field_idx + 1;
        } else if (key.matches(vaxis.Key.enter, .{})) {
            if (self.active_field_idx == NUMBER_OF_FIELDS - 1) {
                // do things here
            } else {
                self.active_field_idx += 1;
            }
        } else {
            try self.inputs[self.active_field_idx].handle_input(key);
        }

        self.inputs[self.active_field_idx].focus();
    }

    pub fn draw(self: *InputListWidget, win: Window) !void {
        for (self.inputs, 0..) |*input, i| {
            const y_offset = usize_to(u16, Input.TOTAL_HEIGHT * i);

            const child = win.child(.{ .x_off = 1, .y_off = @intCast(y_offset), .width = win.width - 2, .height = Input.TOTAL_HEIGHT });
            try input.draw(child);
        }
    }
};
