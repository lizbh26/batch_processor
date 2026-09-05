const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;

const Arena = std.heap.ArenaAllocator;
const usize_to = @import("~").utils.usize_to;

const Process = @import("~").models.Process.Process;

const InputListWidget = @import("components/input_list.zig").InputListWidget;
const Input = @import("components/input_with_label.zig");

const inputs = [_]Input.WidgetConfig{
    .{ .label = "Nombre del programador", .maxInputSize = 50, .type = .text },
    .{ .label = "ID del programa", .maxInputSize = 20, .type = .text },
    .{ .label = "Operación", .maxInputSize = 20, .type = .operation },
    .{ .label = "Tiempo Máximo Estimado", .maxInputSize = 3, .type = .number },
};

pub const EditProcessWidget = struct {
    arena: Arena,

    current_process: *Process,
    inputList: InputListWidget,

    pub fn init(self: *EditProcessWidget, alloc: std.mem.Allocator) void {
        self.arena = Arena.init(alloc);
        self.inputList.init(&.{ .alloc = alloc, .inputs = &inputs });
    }

    pub fn deinit(self: *EditProcessWidget) void {
        self.arena.deinit();
    }

    pub fn setProcessToEdit(self: *EditProcessWidget, p: *Process) void {
        if (p == self.current_process) return;
        self.current_process = p;
        self.inputList.reset();
    }

    pub fn handleInput(self: *EditProcessWidget, key: vaxis.Key) !void {
        try self.inputList.handleInput(key);
    }

    pub fn draw(self: *EditProcessWidget, win: Window) !void {
        try self.inputList.draw(win);
    }
};
