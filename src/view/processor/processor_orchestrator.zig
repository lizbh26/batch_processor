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
const Footer = @import("footer.zig").FooterWidget;

const HEADER_WIDTH = 2;
const FOOTER_WIDTH = 2;
pub const ProcessorOrchestratorWidget = struct {
    arena: Arena,
    ctx: *ExecutionContext,

    header: Header,
    pendingProcessesPanel: PendingProcessesPanelWidget,
    currentProcessPanel: CurrentProcessExecutionPanelWidget,
    completedProcessesPanel: CompletedProcessesPanelWidget,
    footer: Footer,

    running: bool,

    pub fn init(self: *ProcessorOrchestratorWidget, extern_alloc: std.mem.Allocator, ctx: *ExecutionContext) void {
        self.arena = Arena.init(extern_alloc);
        const alloc = self.arena.allocator();

        self.ctx = ctx;
        self.running = true;

        self.header.init(alloc);
        self.pendingProcessesPanel.init(alloc, self.ctx);
        self.currentProcessPanel.init(alloc, self.ctx);
        self.completedProcessesPanel.init(alloc, self.ctx);
        self.footer.init(alloc);
    }

    pub fn deinit(self: *ProcessorOrchestratorWidget) void {
        self.arena.deinit();
    }

    pub fn handleInput(self: *ProcessorOrchestratorWidget, key: vaxis.Key) !void {
        if (!self.ctx.isComplete()) {
            if (self.running) {
                if (key.matches('e', .{})) {
                    try self.ctx.getCurrentBatch().moveToNext();
                } else if (key.matches('w', .{})) {
                    self.ctx.failCurrentProcess();
                } else if (key.matches('p', .{})) {
                    self.running = false;
                }
            } else if (key.matches('c', .{})) {
                self.running = true;
            }
        }
        self.completedProcessesPanel.handleInput(key);
    }

    pub fn kickstart(self: *ProcessorOrchestratorWidget, now: zeit.Instant) !void {
        self.header.timerWidget.kickstart(now);
        try self.completedProcessesPanel.kickstart();

        try self.run(now);
    }
    pub fn run(self: *ProcessorOrchestratorWidget, now: zeit.Instant) !void {
        try self.header.timerWidget.tick(now);
        self.currentProcessPanel.tick(now);
        try self.footer.showRunningControls();
    }
    pub fn stop(self: *ProcessorOrchestratorWidget) !void {
        self.header.timerWidget.stop();
        self.currentProcessPanel.stop();
        try self.footer.showPausedControls();
    }

    pub fn tick(self: *ProcessorOrchestratorWidget, now: zeit.Instant) !void {
        if (self.ctx.isComplete()) return;
        if (self.running)
            try self.run(now)
        else
            try self.stop();
    }

    pub fn draw(self: *ProcessorOrchestratorWidget, win: Window) !void {
        try self.drawHeader(win);
        try self.drawPanels(win);
        try self.drawFooter(win);
        win.hideCursor();
    }

    fn drawHeader(self: *ProcessorOrchestratorWidget, win: Window) !void {
        if (!self.ctx.isComplete()) {
            const remainingBatches = self.ctx.batches.len - self.ctx.current_batch - 1;
            try self.header.setRemainingBatchesLabel(remainingBatches);
        }

        const headerContainer = win.child(.{ .x_off = 0, .y_off = 0, .width = win.width, .height = HEADER_WIDTH, .border = .{ .where = .bottom, .style = .{ .fg = .{ .index = 255 } } } });
        try self.header.draw(headerContainer);
    }
    fn drawPanels(self: *ProcessorOrchestratorWidget, win: Window) !void {
        const panelWidth = @divFloor(win.width, 3);
        const mainContainer = win.child(.{ .x_off = 0, .y_off = HEADER_WIDTH + 1, .width = win.width, .height = win.height - HEADER_WIDTH - 1 - FOOTER_WIDTH });

        const pendingProcessesPanelChild = mainContainer.child(.{ .x_off = 0, .y_off = 0, .width = panelWidth, .height = mainContainer.height });
        try self.pendingProcessesPanel.draw(pendingProcessesPanelChild);

        const currentProcessPanelChild = mainContainer.child(.{ .x_off = panelWidth + 1, .y_off = 0, .width = panelWidth, .height = mainContainer.height });
        try self.currentProcessPanel.draw(currentProcessPanelChild);

        const completedProcessesPanelChild = mainContainer.child(.{ .x_off = panelWidth * 2 + 1, .y_off = 0, .width = panelWidth, .height = mainContainer.height });
        try self.completedProcessesPanel.draw(completedProcessesPanelChild);
    }
    fn drawFooter(self: *ProcessorOrchestratorWidget, win: Window) !void {
        const footerContainer = win.child(.{ .x_off = 0, .y_off = win.height - FOOTER_WIDTH - 1, .width = win.width, .height = FOOTER_WIDTH, .border = .{ .where = .top, .style = .{ .fg = .{ .index = 255 } } } });
        try self.footer.draw(footerContainer);
    }
};
