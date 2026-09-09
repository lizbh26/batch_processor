const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;

const Arena = std.heap.ArenaAllocator;

const ExecutionContext = @import("~").models.Context.ExecutionContext;

const ContextBootstrapperWidget = @import("context_bootstrapper.zig").ContextBootstrapperWidget;

pub const InputOrchestratorWidget = struct {
    arena: Arena,
    ctx: *ExecutionContext,
    random: std.Random,

    bootstrap_widget: ContextBootstrapperWidget,

    pub fn init(self: *InputOrchestratorWidget, extern_alloc: std.mem.Allocator, random: std.Random, ctx: *ExecutionContext) void {
        self.arena = Arena.init(extern_alloc);
        const alloc = self.arena.allocator();
        self.ctx = ctx;
        self.random = random;

        self.bootstrap_widget.init(alloc);
    }
    pub fn deinit(self: *InputOrchestratorWidget) void {
        self.arena.deinit();
    }

    pub fn handleInput(self: *InputOrchestratorWidget, key: vaxis.Key) !void {
        try self.bootstrap_widget.handleInput(key);
    }

    pub fn tick(self: *InputOrchestratorWidget) !void {
        if (self.bootstrap_widget.isDone()) {
            try self.bootstrap_widget.prepareContext(self.random, self.ctx);
        }
    }

    pub fn draw(self: *InputOrchestratorWidget, win: Window) !void {
        try self.bootstrap_widget.draw(win);
    }
};
