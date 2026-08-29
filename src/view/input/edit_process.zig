const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;

const Arena = std.heap.ArenaAllocator;

const Process = @import("~").Process;

const Input = @import("components/input_with_label.zig");

const MAX_CHARS_FOR_LABELS = 18; //update this if largest label changes size
const process_fields = [_][]const u8{ "ID", "Nombre del usuario", "Operación", "Tiempo estimado" };

const NUMBER_OF_FIELDS = process_fields.len;

fn sample_validator(input: []const u8) []const u8 {
    if (input.len == 0) return "El campo es requerido";
    return "";
}

pub const EditProcessWidget = struct {
    arena: Arena,

    inputs: [NUMBER_OF_FIELDS]*Input.InputWithLabelWidget,
    current_process: *Process,
    active_field_idx: u8,

    pub fn init(alloc: std.mem.Allocator) !*EditProcessWidget {
        const self = try alloc.create(EditProcessWidget);
        errdefer alloc.destroy(self);

        self.arena = Arena.init(alloc);
        errdefer self.arena.deinit();

        for (process_fields, 0..) |label, i| {
            self.inputs[i] = try Input.InputWithLabelWidget.init(self.arena.allocator(), label, &sample_validator);
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
        for (self.inputs, 0..) |input, i| {
            const minimum_y_offset = @min(Input.TOTAL_HEIGHT * i, @as(usize, std.math.maxInt(i17)));

            const child = win.child(.{ .x_off = 1, .y_off = @intCast(minimum_y_offset), .width = win.width - 2, .height = Input.TOTAL_HEIGHT });
            try input.draw(child, MAX_CHARS_FOR_LABELS + 2);
        }
    }
};
