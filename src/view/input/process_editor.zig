const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;

const Arena = std.heap.ArenaAllocator;
const usize_to = @import("~").utils.usize_to;

const Process = @import("~").models.Process.Process;
const Operation = @import("~").models.Operation.Operation;
const ExecutionContext = @import("~").models.Context.ExecutionContext;

const InputListWidget = @import("components/input_list.zig").InputListWidget;
const Input = @import("components/input.zig");

const CtxValidators = @import("utils/ctx_validators.zig");

var inputs = [_]Input.WidgetConfig{
    .{ .label = "Nombre del programador", .maxInputSize = 50, .type = .text },
    .{ .label = "ID del programa", .maxInputSize = 20, .type = .text },
    .{ .label = "Operación", .maxInputSize = 20, .type = .operation },
    .{ .label = "Tiempo Máximo Estimado", .maxInputSize = 3, .type = .number },
};

const WidgetConfig = struct { ctx: *ExecutionContext };
pub const EditProcessWidget = struct {
    arena: Arena,

    ctx: *ExecutionContext,
    inputList: InputListWidget,

    pub fn init(self: *EditProcessWidget, alloc: std.mem.Allocator, config: WidgetConfig) void {
        self.arena = Arena.init(alloc);

        inputs[1].ctxValidator = CtxValidators.validateUniqueId;
        inputs[1].ctx = config.ctx;

        self.ctx = config.ctx;
        self.inputList.init(&.{ .alloc = alloc, .inputs = &inputs });
    }

    pub fn deinit(self: *EditProcessWidget) void {
        self.arena.deinit();
    }

    pub fn finishEdit(self: *EditProcessWidget) !void {
        const alloc = self.ctx.arena.allocator();
        const process = self.ctx.getCurrentProcess();

        const batchIdx, _ = self.ctx.getBatchAndProcessIdx();
        process.batchIdx = batchIdx;

        process.username = try alloc.dupe(u8, self.inputList.getInputAt(0));
        process.id = try alloc.dupe(u8, self.inputList.getInputAt(1));
        process.operation = Operation.fromString(self.inputList.getInputAt(2));
        process.tme_ms = (std.fmt.parseInt(i128, self.inputList.getInputAt(3), 10) catch unreachable) * 1000;
        process.tt_ms = 0;

        self.inputList.reset();
    }
    pub fn isDone(self: *EditProcessWidget) bool {
        return self.inputList.isDone();
    }

    pub fn handleInput(self: *EditProcessWidget, key: vaxis.Key) !void {
        try self.inputList.handleInput(key);
    }

    pub fn draw(self: *EditProcessWidget, win: Window) !void {
        try self.inputList.title.changeText(try std.fmt.allocPrint(self.arena.allocator(), "Ingresa el proceso {d} de {d}", .{ self.ctx.current_process_idx + 1, self.ctx.process_count }));
        try self.inputList.draw(win);
    }
};
