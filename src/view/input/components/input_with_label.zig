const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;
const TextView = vaxis.widgets.TextView;
const TextInput = vaxis.widgets.TextInput;

const Arena = std.heap.ArenaAllocator;

const INPUT_HEIGHT = 3;
const ERROR_LABEL_HEIGHT = 2;
pub const TOTAL_HEIGHT = INPUT_HEIGHT + ERROR_LABEL_HEIGHT;

pub const ValidatorFnType = ?*const fn (input: []const u8) []const u8;
pub const InputWithLabelWidget = struct {
    arena: Arena,

    label_view: TextView,
    label_buffer: TextView.Buffer,

    input: TextInput,
    focused: bool,

    error_view: TextView,
    error_buffer: TextView.Buffer,
    validator: ValidatorFnType,

    pub fn init(extern_alloc: std.mem.Allocator, label: []const u8, validatorFn: ValidatorFnType) !*InputWithLabelWidget {
        const self = try extern_alloc.create(InputWithLabelWidget);
        errdefer extern_alloc.destroy(self);

        self.arena = Arena.init(extern_alloc);
        errdefer self.arena.deinit();

        const alloc = self.arena.allocator();

        self.label_view = .{};
        self.label_buffer = TextView.Buffer{};
        try self.label_buffer.append(alloc, .{ .bytes = label });

        self.error_view = .{};
        self.error_buffer = TextView.Buffer{};
        try self.error_buffer.updateStyle(alloc, .{ .style = .{ .fg = .{ .rgb = .{ 255, 0, 0 } }, .blink = true }, .begin = 0, .end = 1024 });

        self.validator = validatorFn;

        self.input = TextInput.init(alloc);
        self.focused = false;

        return self;
    }

    pub fn deinit(self: *InputWithLabelWidget, alloc: std.mem.Allocator) void {
        self.arena.deinit();
        alloc.destroy(self);
    }

    pub fn handle_input(self: *InputWithLabelWidget, key: vaxis.Key) !void {
        try self.input.update(.{ .key_press = key });
    }

    pub fn focus(self: *InputWithLabelWidget) void {
        self.focused = true;
    }
    pub fn unfocus(self: *InputWithLabelWidget) void {
        self.focused = false;
    }

    pub fn draw(self: *InputWithLabelWidget, win: vaxis.Window, max_label_space: u16) !void {
        const label_child = win.child(.{ .x_off = 0, .y_off = 1, .width = max_label_space, .height = 1 });
        self.label_view.draw(label_child, self.label_buffer);

        const input_error_wrapper = win.child(.{ .x_off = max_label_space, .y_off = 0, .width = win.width - max_label_space, .height = INPUT_HEIGHT + ERROR_LABEL_HEIGHT });
        input_error_wrapper.hideCursor();

        const input_child = input_error_wrapper.child(.{ .y_off = 1, .width = input_error_wrapper.width, .height = INPUT_HEIGHT - 1, .border = .{ .where = .bottom, .style = .{ .fg = .{ .index = if (self.focused) 255 else 56 } } } });
        self.input.draw(input_child);

        const input_text = try self.input.toOwnedContents(self.alloc);
        defer self.alloc.free(input_text);

        const error_text = if (self.validator) |func| func(input_text) else "";
        if (error_text.len > 0) {
            const error_child = input_error_wrapper.child(.{ .y_off = INPUT_HEIGHT, .width = input_error_wrapper.width, .height = ERROR_LABEL_HEIGHT });
            error_child.hideCursor();

            self.error_buffer.clear(self.alloc);
            try self.error_buffer.append(self.alloc, .{ .bytes = error_text });

            self.error_view.draw(error_child, self.error_buffer);
        }

        win.hideCursor();
    }
};
