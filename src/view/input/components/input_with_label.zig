const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;
const TextView = vaxis.widgets.TextView;
const TextInput = vaxis.widgets.TextInput;

const Arena = std.heap.ArenaAllocator;
const usize_to = @import("~").utils.usize_to;
const leftpad = @import("~").utils.leftpad;

const INPUT_HEIGHT = 3;
const ERROR_LABEL_HEIGHT = 2;
pub const TOTAL_HEIGHT = INPUT_HEIGHT + ERROR_LABEL_HEIGHT;

const Validator = @import("../utils/validators.zig").Validators;
pub const ValidatorFnType = ?*const fn (input: []const u8) []const u8;

pub const InputType = enum { text, number };
pub const WidgetConfig = struct { label: []const u8, maxInputSize: ?u16, validatorFn: ValidatorFnType, type: InputType };

pub const InputWidget = struct {
    arena: Arena,

    fieldLabel: Label,
    errorLabel: Label,

    input: TextInput,
    focused: bool = false,

    config: WidgetConfig,

    pub fn init(self: *InputWidget, extern_alloc: std.mem.Allocator, maxLabelSize: ?u16, config: WidgetConfig) !void {
        self.arena = Arena.init(extern_alloc);
        errdefer self.arena.deinit();
        const alloc = self.arena.allocator();

        var padded_label = config.label;
        if (maxLabelSize) |max_size| {
            if (config.label.len < max_size)
                padded_label = leftpad(config.label, max_size - config.label.len, ' ', alloc);
        }

        self.config = config;
        self.config.label = padded_label;

        try self.fieldLabel.init(alloc);
        try self.fieldLabel.changeText(padded_label);

        try self.errorLabel.init(alloc);

        self.input = TextInput.init(alloc);
        self.focused = false;
    }

    pub fn deinit(self: *InputWidget) void {
        self.arena.deinit();
    }

    pub fn handle_input(self: *InputWidget, key: vaxis.Key) !void {
        if (self.config.maxInputSize) |max_size| {
            if (self.input.buf.realLength() >= max_size) return;
        }

        if (self.config.type == .number and !Validator.only_numbers(key.text orelse "")) {
            return;
        }

        try self.input.update(.{ .key_press = key });
    }

    pub fn focus(self: *InputWidget) void {
        self.focused = true;
    }
    pub fn unfocus(self: *InputWidget) void {
        self.focused = false;
    }

    pub fn getInputText(self: *InputWidget, alloc: std.mem.Allocator) []const u8 {
        return self.input.toOwnedContents(alloc) catch "";
    }

    fn validateInput(self: *InputWidget, alloc: std.mem.Allocator) []const u8 {
        const input_text = self.getInputText(alloc);
        defer alloc.free(input_text);

        return if (self.config.validatorFn) |func| func(input_text) else "";
    }

    pub fn draw(self: *InputWidget, win: vaxis.Window) !void {
        const max_label_size: u16 = usize_to(u16, self.fieldLabel.getWidth());

        const label_child = win.child(.{ .x_off = 0, .y_off = 1, .width = max_label_size + 1, .height = 1 });
        self.fieldLabel.draw(label_child);

        const input_error_wrapper = win.child(.{ .x_off = max_label_size + 2, .y_off = 0, .width = win.width - max_label_size, .height = INPUT_HEIGHT + ERROR_LABEL_HEIGHT });

        var max_input_size = input_error_wrapper.width;
        if (self.config.maxInputSize) |max_size| max_input_size = @min(max_size, max_input_size);

        const input_child = input_error_wrapper.child(.{ .y_off = 1, .width = max_input_size, .height = INPUT_HEIGHT - 1, .border = .{ .where = .bottom, .style = .{ .fg = .{ .index = if (self.focused) 255 else 56 } } } });
        self.input.draw(input_child);

        const alloc = self.arena.allocator();
        const error_text = self.validateInput(alloc);

        if (error_text.len > 0) {
            try self.errorLabel.changeText(error_text);
            const error_child = input_error_wrapper.child(.{ .y_off = INPUT_HEIGHT, .width = input_error_wrapper.width, .height = ERROR_LABEL_HEIGHT });
            self.errorLabel.draw(error_child);
        }
    }
};
