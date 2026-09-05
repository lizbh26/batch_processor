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

pub const Widget = struct {
    arena: Arena,

    label_view: TextView,
    label_buffer: TextView.Buffer,

    input: TextInput,
    focused: bool = false,

    error_view: TextView,
    error_buffer: TextView.Buffer,

    config: WidgetConfig,

    pub fn init(extern_alloc: std.mem.Allocator, maxLabelSize: ?u16, config: WidgetConfig) !*Widget {
        const self = try extern_alloc.create(Widget);
        errdefer extern_alloc.destroy(self);

        self.setDefaults(extern_alloc, maxLabelSize, config);

        return self;
    }
    pub fn setDefaults(self: *Widget, extern_alloc: std.mem.Allocator, maxLabelSize: ?u16, config: WidgetConfig) !void {
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

        self.label_view = .{};
        self.label_buffer = TextView.Buffer{};
        try self.label_buffer.append(alloc, .{ .bytes = padded_label });

        self.error_view = .{};
        self.error_buffer = TextView.Buffer{};
        const error_style: TextView.Buffer.Style = .{ .style = .{ .fg = .{ .rgb = .{ 255, 0, 0 } }, .blink = true }, .begin = 0, .end = 1024 };
        try self.error_buffer.updateStyle(alloc, error_style);

        self.input = TextInput.init(alloc);
        self.focused = false;
    }

    pub fn deinit(self: *Widget, alloc: std.mem.Allocator) void {
        self.arena.deinit();
        alloc.destroy(self);
    }

    pub fn handle_input(self: *Widget, key: vaxis.Key) !void {
        if (self.config.maxInputSize) |max_size| {
            if (self.input.buf.realLength() >= max_size) return;
        }

        if (self.config.type == .number and !Validator.only_numbers(key.text orelse "")) {
            return;
        }

        try self.input.update(.{ .key_press = key });
    }

    pub fn focus(self: *Widget) void {
        self.focused = true;
    }
    pub fn unfocus(self: *Widget) void {
        self.focused = false;
    }

    pub fn getInputText(self: *Widget) []const u8 {
        return self.input.toOwnedContents(self.arena.allocator()) catch "";
    }

    fn validateInput(self: *Widget, alloc: std.mem.Allocator) []const u8 {
        const input_text = self.getInputText();
        defer alloc.free(input_text);

        return if (self.config.validatorFn) |func| func(input_text) else "";
    }

    pub fn draw(self: *Widget, win: vaxis.Window) !void {
        const max_label_size: u16 = usize_to(u16, self.config.label.len);

        const label_child = win.child(.{ .x_off = 0, .y_off = 1, .width = max_label_size + 1, .height = 1 });
        self.label_view.draw(label_child, self.label_buffer);

        const input_error_wrapper = win.child(.{ .x_off = max_label_size + 2, .y_off = 0, .width = win.width - max_label_size, .height = INPUT_HEIGHT + ERROR_LABEL_HEIGHT });

        var max_input_size = input_error_wrapper.width;
        if (self.config.maxInputSize) |max_size| max_input_size = @min(max_size, max_input_size);

        const input_child = input_error_wrapper.child(.{ .y_off = 1, .width = max_input_size, .height = INPUT_HEIGHT - 1, .border = .{ .where = .bottom, .style = .{ .fg = .{ .index = if (self.focused) 255 else 56 } } } });
        self.input.draw(input_child);

        const alloc = self.arena.allocator();

        const error_text = self.validateInput(alloc);

        if (error_text.len > 0) {
            const error_child = input_error_wrapper.child(.{ .y_off = INPUT_HEIGHT, .width = input_error_wrapper.width, .height = ERROR_LABEL_HEIGHT });

            self.error_buffer.clear(alloc);
            try self.error_buffer.append(alloc, .{ .bytes = error_text });

            self.error_view.draw(error_child, self.error_buffer);
        }
    }
};
