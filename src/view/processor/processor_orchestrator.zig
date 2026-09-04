const std = @import("std");
const zeit = @import("zeit");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;

const models = @import("~").models;
const ExecutionContext = models.Context.ExecutionContext;

const Arena = std.heap.ArenaAllocator;
const usize_to = @import("~").utils.usize_to;

const mockCtx = @import("_utils/mock_ctx.zig").createMockContext;

const Header = @import("header/index.zig").Header;
const PendingProcessesPanelWidget = @import("pending_processes.zig").PendingProcessesWidget;
const CompletedProcessesPanelWidget = @import("completed_processes.zig").CompletedProcessesWidget;

pub const ProcessorOrchestratorWidget = struct {
    ctx: *ExecutionContext,

    header: *Header,
    pendingProcessesPanel: *PendingProcessesPanelWidget,
    completedProcessesPanel: *CompletedProcessesPanelWidget,

    pub fn init(alloc: std.mem.Allocator, io: std.Io) !*ProcessorOrchestratorWidget {
        const self = try alloc.create(ProcessorOrchestratorWidget);

        self.ctx = try mockCtx(alloc);
        self.header = try Header.init(alloc, io);
        self.pendingProcessesPanel = try PendingProcessesPanelWidget.init(alloc, self.ctx);
        self.completedProcessesPanel = try CompletedProcessesPanelWidget.init(alloc, self.ctx);

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

    pub fn tick(self: *ProcessorOrchestratorWidget, now: zeit.Instant) !void {
        try self.header.tick(now);
    }

    pub fn draw(self: *ProcessorOrchestratorWidget, win: Window) !void {
        const panelWidth = win.width / 3;

        const headerContainer = win.child(.{ .x_off = 0, .y_off = 0, .width = win.width, .height = 2, .border = .{ .where = .bottom, .style = .{ .fg = .{ .index = 255 } } } });
        try self.header.draw(headerContainer);

        const mainContainer = win.child(.{ .x_off = 0, .y_off = 3, .width = win.width, .height = win.height - 2 });

        const pendingProcessesPanelChild = mainContainer.child(.{ .x_off = 0, .y_off = 0, .width = panelWidth - 2, .height = mainContainer.height });
        try self.pendingProcessesPanel.draw(pendingProcessesPanelChild);

        const completedProcessesPanelChild = mainContainer.child(.{ .x_off = panelWidth * 2 + 1, .y_off = 0, .width = panelWidth - 2, .height = mainContainer.height });
        try self.completedProcessesPanel.draw(completedProcessesPanelChild);
    }
};
