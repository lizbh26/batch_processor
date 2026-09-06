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

    running: bool,

    pub fn init(self: *ProcessorOrchestratorWidget, extern_alloc: std.mem.Allocator, ctx: *ExecutionContext) void {
        self.arena = Arena.init(extern_alloc);
        const alloc = self.arena.allocator();

        self.ctx = ctx;
        self.running = false;

        self.header.init(alloc);
        self.pendingProcessesPanel.init(alloc, self.ctx);
        self.currentProcessPanel.init(alloc, self.ctx);
        self.completedProcessesPanel.init(alloc, self.ctx);
    }

    pub fn deinit(self: *ProcessorOrchestratorWidget) void {
        self.arena.deinit();
    }

    pub fn handleInput(self: *ProcessorOrchestratorWidget, key: vaxis.Key) !void {
        self.completedProcessesPanel.handleInput(key);
    }

    pub fn run(self: *ProcessorOrchestratorWidget, now: zeit.Instant) !void {
        self.running = true;
        self.header.timerWidget.run(now);
        self.currentProcessPanel.run(now);
        try self.completedProcessesPanel.run();
    }

    pub fn tick(self: *ProcessorOrchestratorWidget, now: zeit.Instant) !void {
        if (!self.ctx.isComplete() and self.running) {
            try self.header.tick(now);
            self.currentProcessPanel.tick(now);
        }
    }

    pub fn draw(self: *ProcessorOrchestratorWidget, win: Window) !void {
        try self.drawHeader(win);
        try self.drawPanels(win);
        win.hideCursor();
    }

    fn drawHeader(self: *ProcessorOrchestratorWidget, win: Window) !void {
        if (!self.ctx.isComplete()) {
            const currBatchIdx, _ = self.ctx.getBatchAndProcessIdx();
            const remainingBatches = self.ctx.batches.len - currBatchIdx - 1;

            const plural_S = if (remainingBatches == 1) "" else "s";
            try self.header.title.changeText(if (remainingBatches > 0) try std.fmt.allocPrint(self.arena.allocator(), "{d} lote{s} pendiente{s}", .{ remainingBatches, plural_S, plural_S }) else "");
        }

        const headerContainer = win.child(.{ .x_off = 0, .y_off = 0, .width = win.width, .height = 2, .border = .{ .where = .bottom, .style = .{ .fg = .{ .index = 255 } } } });
        try self.header.draw(headerContainer);
    }
    fn drawPanels(self: *ProcessorOrchestratorWidget, win: Window) !void {
        const panelWidth = @divFloor(win.width, 3);
        const mainContainer = win.child(.{ .x_off = 0, .y_off = 3, .width = win.width, .height = win.height - 2 });

        const pendingProcessesPanelChild = mainContainer.child(.{ .x_off = 0, .y_off = 0, .width = panelWidth, .height = mainContainer.height });
        try self.pendingProcessesPanel.draw(pendingProcessesPanelChild);

        const currentProcessPanelChild = mainContainer.child(.{ .x_off = panelWidth + 1, .y_off = 0, .width = panelWidth, .height = mainContainer.height });
        try self.currentProcessPanel.draw(currentProcessPanelChild);

        const completedProcessesPanelChild = mainContainer.child(.{ .x_off = panelWidth * 2 + 1, .y_off = 0, .width = panelWidth, .height = mainContainer.height });
        try self.completedProcessesPanel.draw(completedProcessesPanelChild);
    }
};
