const std = @import("std");
const vaxis = @import("vaxis");
const Arena = std.heap.ArenaAllocator;

const Process = @import("~").models.Process.Process;
const Context = @import("~").models.Context;

const Window = vaxis.Window;
const ProcessCardWidget = @import("components/process_card.zig").ProcessCard;
const Label = @import("../components/label.zig").LabelWidget;

const usize_to = @import("~").utils.usize_to;

const MAX_CARDS_TO_SHOW = Context.MAX_PROCESSES_IN_MEMORY - 1;
pub const PendingProcessesWidget = struct {
    arena: Arena,
    ctx: *Context.ExecutionContext,

    title: Label,
    cards: [MAX_CARDS_TO_SHOW]ProcessCardWidget,

    pub fn init(self: *PendingProcessesWidget, extern_alloc: std.mem.Allocator, ctx: *Context.ExecutionContext) void {
        self.arena = Arena.init(extern_alloc);
        self.ctx = ctx;

        const alloc = self.arena.allocator();
        self.title.init(alloc);
        for (0..self.cards.len) |i| {
            self.cards[i].init(alloc, .pending);
        }
    }

    pub fn deinit(self: *PendingProcessesWidget, alloc: std.mem.Allocator) void {
        for (self.cards) |*card| {
            card.deinit(alloc);
        }
        self.arena.deinit();
    }

    fn getPending(self: *PendingProcessesWidget, processes: *[MAX_CARDS_TO_SHOW]?*Process) !void {
        if (self.ctx.isComplete()) return;

        const queue = self.ctx.ready_queue;
        const len = queue.length();

        for (1..len) |i| {
            const p = self.ctx.ready_queue.get(i) catch unreachable;
            processes[i] = p;
        }
        for (len..MAX_CARDS_TO_SHOW) |i| {
            processes[i] = null;
        }
    }

    pub fn draw(self: *PendingProcessesWidget, win: Window) !void {
        const alloc = self.arena.allocator();

        var processes: [MAX_CARDS_TO_SHOW]?*Process = [_]?*Process{null} ** MAX_CARDS_TO_SHOW;
        try self.getPending(&processes);

        var n: u16 = 0;
        var y_off: u16 = 1;
        for (processes, 0..) |process, i| {
            const card = &self.cards[i];

            const p = process orelse {
                card.process = null;
                continue;
            };

            try card.updateProcess(p);
            n += 1;

            const height = card.getHeight();
            const child = win.child(.{ .x_off = @divTrunc(win.width - card.getWidth(win), 2), .y_off = y_off, .width = win.width, .height = height });
            card.draw(child);
            y_off += height;
        }

        const plural_S = if (n == 1) "" else "s";
        const msg: []const u8 = if (n == 0) "Sin procesos pendientes" else try std.fmt.allocPrint(alloc, "{d} proceso{s} pendiente{s} en el lote", .{ n, plural_S, plural_S });
        try self.title.changeText(msg);

        const titleWidth = usize_to(u16, self.title.getWidth());
        const titleChild = win.child(.{ .x_off = @divTrunc(win.width - titleWidth, 2), .y_off = 0, .width = titleWidth, .height = 1 });
        self.title.draw(titleChild);
    }
};
