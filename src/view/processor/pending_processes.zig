const std = @import("std");
const vaxis = @import("vaxis");
const Arena = std.heap.ArenaAllocator;

const Process = @import("~").models.Process;
const Context = @import("~").models.Context;

const Window = vaxis.Window;
const ProcessCardWidget = @import("components/process_card.zig").ProcessCard;
const BlockedProcessCardWidget = @import("components/blocked_process_card.zig").BlockedProcessCard;
const Label = @import("../components/label.zig").LabelWidget;

const usize_to = @import("~").utils.usize_to;

const MAX_CARDS_TO_SHOW = Context.MAX_PROCESSES_IN_MEMORY;
pub const PendingProcessesWidget = struct {
    const Self = @This();

    arena: Arena,
    ctx: *Context.ExecutionContext,

    ready_title: Label,
    ready_cards: [MAX_CARDS_TO_SHOW]ProcessCardWidget,

    blocked_title: Label,
    blocked_cards: [MAX_CARDS_TO_SHOW]BlockedProcessCardWidget,

    pub fn init(self: *PendingProcessesWidget, extern_alloc: std.mem.Allocator, ctx: *Context.ExecutionContext) void {
        self.ctx = ctx;

        self.arena = Arena.init(extern_alloc);
        const alloc = self.arena.allocator();

        self.ready_title.init(alloc);
        for (&self.ready_cards) |*card| {
            card.init(alloc, .pending);
        }

        self.blocked_title.init(alloc);
        for (&self.blocked_cards) |*card| {
            card.init(alloc);
        }
    }

    pub fn deinit(self: *PendingProcessesWidget) void {
        const alloc = self.arena.allocator();
        for (&self.ready_cards) |*card| {
            card.deinit(alloc);
        }
        for (&self.blocked_cards) |card| {
            card.deinit(alloc);
        }
        self.arena.deinit();
    }

    pub fn draw(self: *PendingProcessesWidget, win: Window) !void {
        try self.updateReadyCards();
        try self.updateBlockedCards();

        const alloc = self.arena.allocator();
        const height = try self.drawReadyQueue(win, alloc);

        const blockedContainer = win.child(.{ .y_off = height + 2 });
        try self.drawBlockedQueue(blockedContainer, alloc);
    }
    fn updateReadyCards(self: *Self) !void {
        const queue = &self.ctx.ready_queue;
        for (0..queue.len) |i| {
            const p = queue.get(i) catch unreachable;
            try self.ready_cards[i].updateProcess(p);
        }
        for (queue.len..MAX_CARDS_TO_SHOW) |i| {
            self.ready_cards[i].process = null;
        }
    }
    fn updateBlockedCards(self: *Self) !void {
        const queue = &self.ctx.blocked_queue;
        for (0..queue.len) |i| {
            const p = queue.get(i) catch unreachable;
            try self.blocked_cards[i].updateBlockedProcess(p);
        }
        for (queue.len..MAX_CARDS_TO_SHOW) |i| {
            self.blocked_cards[i].blocked_process = null;
        }
    }
    fn drawReadyQueue(self: *Self, win: Window, alloc: std.mem.Allocator) !u16 {
        const len = self.ctx.ready_queue.len;

        const plural_S = if (len == 1) "" else "s";
        const msg: []const u8 = if (len == 0) "Sin procesos listos" else try std.fmt.allocPrint(alloc, "{d} proceso{s} listo{s} en cola", .{ len, plural_S, plural_S });
        try self.ready_title.changeText(msg);

        const titleWidth = usize_to(u16, self.ready_title.getWidth());
        const titleChild = win.child(.{ .x_off = @divTrunc(win.width - titleWidth, 2), .y_off = 0, .width = titleWidth, .height = 1 });
        self.ready_title.draw(titleChild);

        var y_off: u16 = 1;
        for (&self.ready_cards) |*card| {
            if (card.process == null) continue;

            const height = card.getHeight();
            const child = win.child(.{ .x_off = @divTrunc(win.width - card.getWidth(win), 2), .y_off = y_off, .width = win.width, .height = height });
            card.draw(child);
            y_off += height;
        }

        return y_off;
    }
    fn drawBlockedQueue(self: *Self, win: Window, alloc: std.mem.Allocator) !void {
        const len = self.ctx.blocked_queue.len;
        if (len == 0) return;

        const plural_S = if (len == 1) "" else "s";
        const msg: []const u8 = if (len == 0) "Sin procesos bloqueados" else try std.fmt.allocPrint(alloc, "{d} proceso{s} bloqueado{s}", .{ len, plural_S, plural_S });
        try self.blocked_title.changeText(msg);

        const titleWidth = usize_to(u16, self.blocked_title.getWidth());
        const titleChild = win.child(.{ .x_off = @divTrunc(win.width - titleWidth, 2), .y_off = 0, .width = titleWidth, .height = 1 });
        self.blocked_title.draw(titleChild);

        var y_off: u16 = 1;
        for (&self.blocked_cards) |*card| {
            if (card.blocked_process == null) continue;

            const height = card.getHeight();
            const child = win.child(.{ .x_off = @divTrunc(win.width - card.getWidth(win), 2), .y_off = y_off, .width = win.width, .height = height });
            card.draw(child);
            y_off += height;
        }
    }
};
