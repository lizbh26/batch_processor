const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;

const Arena = std.heap.ArenaAllocator;

const ExecutionContext = @import("~").models.Context.ExecutionContext;

const ContextBootstrapperWidget = @import("context_bootstrapper.zig").ContextBootstrapperWidget;
const EditProcessWidget = @import("process_editor.zig").EditProcessWidget;

pub const InputOrchestratorWidget = struct {
    arena: Arena,
    ctx: *ExecutionContext,

    bootstrap_widget: ContextBootstrapperWidget,
    edit_widget: EditProcessWidget,

    pub fn init(self: *InputOrchestratorWidget, extern_alloc: std.mem.Allocator, ctx: *ExecutionContext) void {
        self.arena = Arena.init(extern_alloc);
        const alloc = self.arena.allocator();
        self.ctx = ctx;

        self.bootstrap_widget.init(alloc);
        self.edit_widget.init(alloc);
    }
    pub fn deinit(self: *InputOrchestratorWidget, extern_alloc: std.mem.Allocator) void {
        self.arena.deinit();
        extern_alloc.destroy(self);
    }

    pub fn proceedToProcessEditing(self: *InputOrchestratorWidget, ctx: ExecutionContext) void {
        self.ctx = ctx;
    }

    pub fn handle_input(self: *InputOrchestratorWidget, key: vaxis.Key) !void {
        if (self.ctx.process_count > 0) {
            try self.edit_widget.handleInput(key);
        } else {
            try self.bootstrap_widget.handleInput(key);
        }
    }

    pub fn tick(self: *InputOrchestratorWidget) !void {
        if (self.ctx.process_count > 0) {
            self.edit_widget.setProcessToEdit(self.ctx.getCurrentProcess());
        } else {
            if (self.bootstrap_widget.isDone()) {
                try self.bootstrap_widget.prepareContext(self.ctx);
            }
        }
    }

    pub fn draw(self: *InputOrchestratorWidget, win: Window) !void {
        if (self.ctx.process_count > 0) {
            try self.edit_widget.draw(win);
        } else {
            try self.bootstrap_widget.draw(win);
        }
    }
};
