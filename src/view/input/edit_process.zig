const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;
const TextView = vaxis.widgets.TextView;
const TextInput = vaxis.widgets.TextInput;

const Arena = std.heap.ArenaAllocator;

const Process = @import("~").Process;

const MAX_CHARS_FOR_LABELS = 18; //update this if largest label changes size
const process_fields = [_][]const u8{ "ID", "Nombre del usuario", "Operación", "Tiempo estimado" };

const NUMBER_OF_FIELDS = process_fields.len;

const INPUT_HEIGHT = 3;
const ERROR_LABEL_HEIGHT = 2;
const FieldInputWithLabelWidget = struct {
    alloc: std.mem.Allocator,

    label_view: TextView,
    label_buffer: TextView.Buffer,

    input: TextInput,
    focused: bool,

    error_view: TextView,
    error_buffer: TextView.Buffer,

    pub fn init(alloc: std.mem.Allocator, label: []const u8) !*FieldInputWithLabelWidget {
        const self = try alloc.create(FieldInputWithLabelWidget);

        self.alloc = alloc;

        self.label_view = .{};
        self.label_buffer = TextView.Buffer{};
        try self.label_buffer.append(alloc, .{ .bytes = label });

        self.error_view = .{};
        self.error_buffer = TextView.Buffer{};
        try self.error_buffer.updateStyle(alloc, .{ .style = .{ .fg = .{ .rgb = .{ 255, 0, 0 } }, .blink = true }, .begin = 0, .end = 1024 });

        self.input = TextInput.init(alloc);
        self.focused = false;

        return self;
    }

    pub fn handle_input(self: *FieldInputWithLabelWidget, key: vaxis.Key) !void {
        try self.input.update(.{ .key_press = key });
    }

    pub fn focus(self: *FieldInputWithLabelWidget) void {
        self.focused = true;
    }
    pub fn unfocus(self: *FieldInputWithLabelWidget) void {
        self.focused = false;
    }

    pub fn draw(self: *FieldInputWithLabelWidget, win: vaxis.Window, error_text: []const u8) !void {
        const label_width: u16 = MAX_CHARS_FOR_LABELS + 2;

        const label_child = win.child(.{ .x_off = 0, .y_off = 1, .width = label_width, .height = 1 });
        self.label_view.draw(label_child, self.label_buffer);

        const input_error_wrapper = win.child(.{ .x_off = label_width, .y_off = 0, .width = win.width - label_width, .height = INPUT_HEIGHT + ERROR_LABEL_HEIGHT });
        input_error_wrapper.hideCursor();

        const input_child = input_error_wrapper.child(.{ .y_off = 1, .width = input_error_wrapper.width, .height = INPUT_HEIGHT - 1, .border = .{ .where = .bottom, .style = .{ .fg = .{ .index = if (self.focused) 255 else 56 } } } });
        self.input.draw(input_child);

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

pub const EditProcessWidget = struct {
    arena: Arena,

    inputs: [NUMBER_OF_FIELDS]*FieldInputWithLabelWidget,
    current_process: *Process,
    active_field_idx: u8,

    pub fn init(alloc: std.mem.Allocator) !*EditProcessWidget {
        const self = try alloc.create(EditProcessWidget);
        errdefer alloc.destroy(self);

        self.arena = Arena.init(alloc);
        errdefer self.arena.deinit();

        for (process_fields, 0..) |label, i| {
            self.inputs[i] = try FieldInputWithLabelWidget.init(self.arena.allocator(), label);
        }
        self.active_field_idx = 0;

        return self;
    }

    pub fn deinit(self: *EditProcessWidget, alloc: std.mem.Allocator) void {
        self.arena.deinit(); // Frees all child widgets and buffers
        alloc.destroy(self); // Frees the widget struct itself
    }

    pub fn setProcessToEdit(self: *EditProcessWidget, p: *Process) void {
        self.current_process = p;
    }

    pub fn handle_input(self: *EditProcessWidget, key: vaxis.Key) !void {
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

    pub fn draw(self: *EditProcessWidget, win: Window) !void {
        const child_height = INPUT_HEIGHT + ERROR_LABEL_HEIGHT;
        for (self.inputs, 0..) |input, i| {
            const clamped_offset: i17 = @intCast(@min(child_height * i, @as(usize, std.math.maxInt(i17))));
            const child = win.child(.{ .x_off = 1, .y_off = clamped_offset, .width = win.width - 2, .height = child_height });
            try input.draw(child, "this is a test error message");
        }
    }
};
