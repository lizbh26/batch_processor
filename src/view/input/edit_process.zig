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
const FieldInputWithLabelWidget = struct {
    label_view: TextView,
    label_buffer: TextView.Buffer,

    input: TextInput,
    focused: bool,

    pub fn init(alloc: std.mem.Allocator, label: []const u8) !*FieldInputWithLabelWidget {
        const self = try alloc.create(FieldInputWithLabelWidget);

        self.label_view = .{};
        self.label_buffer = TextView.Buffer{};
        try self.label_buffer.append(alloc, .{ .bytes = label });

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

    pub fn draw(self: *FieldInputWithLabelWidget, win: vaxis.Window) void {
        const label_width: u16 = MAX_CHARS_FOR_LABELS + 2;

        const label_child = win.child(.{ .x_off = 0, .y_off = 0, .width = label_width, .height = win.height });
        self.label_view.draw(label_child, self.label_buffer);

        const input_child = win.child(.{ .x_off = label_width, .y_off = 0, .width = win.width - label_width, .height = win.height, .border = .{ .where = .bottom, .style = .{ .fg = .{ .index = if (self.focused) 255 else 56 } } } });
        self.input.draw(input_child);
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
        try self.inputs[self.active_field_idx].handle_input(key);
    }

    pub fn draw(self: *EditProcessWidget, win: Window) void {
        for (self.inputs, 0..) |input, i| {
            const clamped_offset: i17 = @intCast(@min(INPUT_HEIGHT * i, @as(usize, std.math.maxInt(i17))));
            const child = win.child(.{ .x_off = 1, .y_off = clamped_offset, .width = win.width - 2, .height = INPUT_HEIGHT });
            input.draw(child);
        }
    }
};
