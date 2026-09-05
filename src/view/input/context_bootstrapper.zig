const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;

const Arena = std.heap.ArenaAllocator;
const usize_to = @import("~").utils.usize_to;

const models = @import("~").models;
const ExecutionContext = models.Context.ExecutionContext;

const InputList = @import("components/input_list.zig");
const Input = @import("components/input_with_label.zig");

const inputs = [_]Input.WidgetConfig{
    .{ .label = "Número de procesos", .maxInputSize = 20, .type = .number },
};

pub const ContextBootstrapperWidget = struct {
    arena: Arena,
    inputList: InputList.InputListWidget,

    pub fn init(self: *ContextBootstrapperWidget, extern_alloc: std.mem.Allocator) void {
        self.arena = Arena.init(extern_alloc);
        self.inputList.init(&.{ .alloc = self.arena.allocator(), .inputs = &inputs });
    }

    pub fn deinit(self: *ContextBootstrapperWidget) void {
        self.arena.deinit();
    }

    pub fn prepareContext(self: *ContextBootstrapperWidget, ctx: *ExecutionContext) !void {
        const processCountInput = self.inputList.getInputAt(0);

        return try ctx.createBatches(std.fmt.parseInt(u16, processCountInput, 10) catch unreachable);
    }
    pub fn isDone(self: *ContextBootstrapperWidget) bool {
        return self.inputList.isDone();
    }

    pub fn handleInput(self: *ContextBootstrapperWidget, key: vaxis.Key) !void {
        try self.inputList.handleInput(key);
    }

    pub fn draw(self: *ContextBootstrapperWidget, win: Window) !void {
        try self.inputList.draw(win);
    }
};
