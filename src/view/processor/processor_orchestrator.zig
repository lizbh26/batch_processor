const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;

const models = @import("~").models;
const ExecutionContext = models.Context.ExecutionContext;

const Arena = std.heap.ArenaAllocator;
const usize_to = @import("~").utils.usize_to;

const mockCtx = @import("_utils/mock_ctx.zig").createMockContext;

const PendingProcessesPanelWidget = @import("pending_processes.zig").PendingProcessesWidget;

pub const ProcessorOrchestratorWidget = struct {
    ctx: *ExecutionContext,

    pendingProcessesPanel: *PendingProcessesPanelWidget,

    pub fn init(alloc: std.mem.Allocator) !*ProcessorOrchestratorWidget {
        const self = try alloc.create(ProcessorOrchestratorWidget);
        self.ctx = try mockCtx(alloc);
        self.pendingProcessesPanel = try PendingProcessesPanelWidget.init(alloc, &self.ctx.batches[0]);
        return self;
    }

    pub fn deinit(self: *ProcessorOrchestratorWidget, alloc: std.mem.Allocator) void {
        alloc.destroy(self.ctx);
        alloc.destroy(self.pendingProcessesPanel);
        alloc.destroy(self);
    }

    pub fn handle_input(_: *ProcessorOrchestratorWidget, _: vaxis.Key) !void {
        //do nothing yet
    }

    pub fn draw(self: *ProcessorOrchestratorWidget, win: Window) !void {
        const panelWidth = win.width / 3;

        const pendingProcessesPanelChild = win.child(.{ .x_off = 0, .y_off = 0, .width = panelWidth - 1, .height = win.height });
        try self.pendingProcessesPanel.draw(pendingProcessesPanelChild);
    }
};
