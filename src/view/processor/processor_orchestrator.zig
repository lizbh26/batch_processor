const std = @import("std");
const zeit = @import("zeit");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;

const models = @import("~").models;
const ExecutionContext = models.Context.ExecutionContext;

const Arena = std.heap.ArenaAllocator;
const usize_to = @import("~").utils.usize_to;

const Header = @import("header/index.zig").Header;
const PendingProcessesPanelWidget = @import("pending_processes.zig").PendingProcessesWidget;
const CurrentProcessExecutionPanelWidget = @import("current_process.zig").CurrentProcessExecutionWidget;
const CompletedProcessesPanelWidget = @import("completed_processes.zig").CompletedProcessesWidget;

pub const ProcessorOrchestratorWidget = struct {
    arena: Arena,
    ctx: *ExecutionContext,

    header: Header,
    pendingProcessesPanel: PendingProcessesPanelWidget,
    currentProcessPanel: CurrentProcessExecutionPanelWidget,
    completedProcessesPanel: CompletedProcessesPanelWidget,

    pub fn init(self: *ProcessorOrchestratorWidget, extern_alloc: std.mem.Allocator, ctx: *ExecutionContext, now: zeit.Instant) void {
        self.arena = Arena.init(extern_alloc);
        const alloc = self.arena.allocator();

        self.ctx = ctx;

        self.header.init(alloc, now);
        self.pendingProcessesPanel.init(alloc, self.ctx);
        self.currentProcessPanel.init(alloc, self.ctx);
        self.completedProcessesPanel.init(alloc, self.ctx);

        self.currentProcessPanel.start(now);

        return self;
    }

    pub fn deinit(self: *ProcessorOrchestratorWidget) void {
        self.arena.deinit();
    }

    pub fn handle_input(_: *ProcessorOrchestratorWidget, _: vaxis.Key) !void {
        //do nothing yet
    }

    pub fn tick(self: *ProcessorOrchestratorWidget, now: zeit.Instant) !void {
        if (!self.ctx.isComplete()) {
            try self.header.tick(now);
            self.currentProcessPanel.tick(now);
        }
    }

    pub fn draw(self: *ProcessorOrchestratorWidget, win: Window) !void {
        const currBatchIdx, _ = self.ctx.getBatchAndProcessIdx();
        const remainingBatches = self.ctx.batches.len - currBatchIdx;

        const plural_S = if (remainingBatches == 1) "" else "s";
        try self.header.title.changeText(if (self.ctx.isComplete()) "Procesamiento terminado" else try std.fmt.allocPrint(self.arena.allocator(), "{d} lote{s} pendiente{s} ({d}/{d})", .{ remainingBatches, plural_S, plural_S, currBatchIdx + 1, self.ctx.batches.len }));
        const headerContainer = win.child(.{ .x_off = 0, .y_off = 0, .width = win.width, .height = 2, .border = .{ .where = .bottom, .style = .{ .fg = .{ .index = 255 } } } });
        try self.header.draw(headerContainer);

        const panelWidth = win.width / 3;
        const mainContainer = win.child(.{ .x_off = 0, .y_off = 3, .width = win.width, .height = win.height - 2 });

        const pendingProcessesPanelChild = mainContainer.child(.{ .x_off = 0, .y_off = 0, .width = panelWidth - 2, .height = mainContainer.height });
        try self.pendingProcessesPanel.draw(pendingProcessesPanelChild);

        const currentProcessPanelChild = mainContainer.child(.{ .x_off = panelWidth + 1, .y_off = 0, .width = panelWidth - 2, .height = mainContainer.height });
        try self.currentProcessPanel.draw(currentProcessPanelChild);

        const completedProcessesPanelChild = mainContainer.child(.{ .x_off = panelWidth * 2 + 1, .y_off = 0, .width = panelWidth - 2, .height = mainContainer.height });
        try self.completedProcessesPanel.draw(completedProcessesPanelChild);

        win.hideCursor();
    }
};
