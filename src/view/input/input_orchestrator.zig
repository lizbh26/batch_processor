const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;

const Arena = std.heap.ArenaAllocator;

const ExecutionContext = @import("~").models.Context.ExecutionContext;

const ContextBootstrapperWidget = @import("context_bootstrapper.zig").ContextBootstrapperWidget;

pub const InputOrchestratorWidget = struct {
    arena: Arena,
    ctx: ?*ExecutionContext,

    bootstrap_widget: *ContextBootstrapperWidget,

    pub fn init(extern_alloc: std.mem.Allocator) !*InputOrchestratorWidget {
        const self = try extern_alloc.create(InputOrchestratorWidget);

        self.arena = Arena.init(extern_alloc);
        const our_alloc = self.arena.allocator();
        self.ctx = null;

        self.bootstrap_widget = try ContextBootstrapperWidget.init(our_alloc);

        return self;
    }
    pub fn deinit(self: *InputOrchestratorWidget, extern_alloc: std.mem.Allocator) void {
        self.arena.deinit();
        extern_alloc.destroy(self);
    }

    pub fn proceedToProcessEditing(self: *InputOrchestratorWidget, ctx: ExecutionContext) void {
        self.ctx = ctx;
    }

    pub fn handle_input(self: *InputOrchestratorWidget, key: vaxis.Key) !void {
        if (self.ctx != null) {
            //Pass event to processes editor
        } else {
            try self.bootstrap_widget.handle_input(key);
        }
    }

    pub fn draw(self: *InputOrchestratorWidget, win: Window) !void {
        if (self.ctx != null) {
            //Screen to edit processes
        } else {
            try self.bootstrap_widget.draw(win);
            if (self.bootstrap_widget.isDone) {
                self.ctx = try self.bootstrap_widget.extractContext(self.arena.allocator());
            }
        }
    }
};
