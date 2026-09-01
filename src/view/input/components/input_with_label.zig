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

pub const ValidatorFnType = ?*const fn (input: []const u8) []const u8;

const InputWithLabelWidgetConfig = struct {
    label: []const u8,
    maxLabelSize: ?u16,
    maxInputSize: ?u16,
    validatorFn: ValidatorFnType,
};

pub const InputWithLabelWidget = struct {
    arena: Arena,

    label_view: TextView,
    label_buffer: TextView.Buffer,

    input: TextInput,
    focused: bool = false,

    error_view: TextView,
    error_buffer: TextView.Buffer,

    config: InputWithLabelWidgetConfig,

    pub fn init(extern_alloc: std.mem.Allocator, config: InputWithLabelWidgetConfig) !*InputWithLabelWidget {
        const self = try extern_alloc.create(InputWithLabelWidget);
        errdefer extern_alloc.destroy(self);

        self.arena = Arena.init(extern_alloc);
        errdefer self.arena.deinit();
        const alloc = self.arena.allocator();

        var padded_label = config.label;
        if (config.maxLabelSize) |max_size| {
            if (config.label.len < max_size)
                padded_label = leftpad(config.label, max_size - config.label.len, alloc);
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

        return self;
    }

    pub fn deinit(self: *InputWithLabelWidget, alloc: std.mem.Allocator) void {
        self.arena.deinit();
        alloc.destroy(self);
    }

    pub fn handle_input(self: *InputWithLabelWidget, key: vaxis.Key) !void {
        if (self.config.maxInputSize) |max_size| {
            if (self.input.buf.realLength() >= max_size) return;
        }

        try self.input.update(.{ .key_press = key });
    }

    pub fn focus(self: *InputWithLabelWidget) void {
        self.focused = true;
    }
    pub fn unfocus(self: *InputWithLabelWidget) void {
        self.focused = false;
    }

    fn validateInput(self: *InputWithLabelWidget, alloc: std.mem.Allocator) ![]const u8 {
        const input_text = try self.input.toOwnedContents(alloc);
        defer alloc.free(input_text);

        return if (self.config.validatorFn) |func| func(input_text) else "";
    }

    pub fn draw(self: *InputWithLabelWidget, win: vaxis.Window) !void {
        const max_label_size: u16 = if (self.config.maxLabelSize) |max_size| max_size else usize_to(u16, self.config.label.len);

        const label_child = win.child(.{ .x_off = 0, .y_off = 1, .width = max_label_size + 1, .height = 1 });
        self.label_view.draw(label_child, self.label_buffer);

        const input_error_wrapper = win.child(.{ .x_off = max_label_size + 2, .y_off = 0, .width = win.width - max_label_size, .height = INPUT_HEIGHT + ERROR_LABEL_HEIGHT });

        var max_input_size = input_error_wrapper.width;
        if (self.config.maxInputSize) |max_size| max_input_size = @min(max_size, max_input_size);

        const input_child = input_error_wrapper.child(.{ .y_off = 1, .width = max_input_size, .height = INPUT_HEIGHT - 1, .border = .{ .where = .bottom, .style = .{ .fg = .{ .index = if (self.focused) 255 else 56 } } } });
        self.input.draw(input_child);

        const alloc = self.arena.allocator();

        const error_text = try self.validateInput(alloc);

        if (error_text.len > 0) {
            const error_child = input_error_wrapper.child(.{ .y_off = INPUT_HEIGHT, .width = input_error_wrapper.width, .height = ERROR_LABEL_HEIGHT });

            self.error_buffer.clear(alloc);
            try self.error_buffer.append(alloc, .{ .bytes = error_text });

            self.error_view.draw(error_child, self.error_buffer);
        }
    }
};
