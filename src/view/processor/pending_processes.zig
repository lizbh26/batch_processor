const std = @import("std");
const vaxis = @import("vaxis");
const Arena = std.heap.ArenaAllocator;

const Process = @import("~").models.Process.Process;
const Batch = @import("~").models.Batch;
const ExecutionContext = @import("~").models.Context.ExecutionContext;

const Window = vaxis.Window;
const ProcessCardWidget = @import("components/process_card.zig").ProcessCard;
const Label = @import("../components/label.zig").LabelWidget;

const usize_to = @import("~").utils.usize_to;

const MAX_CARDS_TO_SHOW = Batch.BATCH_SIZE - 1;
pub const PendingProcessesWidget = struct {
    arena: Arena,
    ctx: *ExecutionContext,

    title: *Label,
    cards: []*ProcessCardWidget,

    pub fn init(extern_alloc: std.mem.Allocator, ctx: *ExecutionContext) !*PendingProcessesWidget {
        const self = try extern_alloc.create(PendingProcessesWidget);
        self.arena = Arena.init(extern_alloc);
        self.ctx = ctx;

        const alloc = self.arena.allocator();
        self.title = try Label.init(alloc);
        self.cards = try self.arena.allocator().alloc(*ProcessCardWidget, MAX_CARDS_TO_SHOW);
        for (0..self.cards.len) |i| {
            self.cards[i] = try ProcessCardWidget.init(alloc, .pending);
        }

        return self;
    }

    pub fn deinit(self: *PendingProcessesWidget, alloc: std.mem.Allocator) void {
        for (self.cards) |*card| {
            card.*.deinit(alloc);
        }
        self.arena.deinit();
        alloc.destroy(self);
    }

    fn getPending(self: *PendingProcessesWidget) ![]?*Process {
        var pending = try self.arena.allocator().alloc(?*Process, MAX_CARDS_TO_SHOW);
        var i: usize = 0;

        const batchIdx, const currentProcessIdx = self.ctx.getBatchAndProcessIdx();
        const batch: *Batch.Batch = &self.ctx.batches[batchIdx];

        for (&batch.queue, 0..) |*process, processIdx| {
            if (processIdx == currentProcessIdx) continue;

            if (process.* == null or process.*.?.isDone()) {
                pending[i] = null;
            } else {
                pending[i] = &(process.*.?);
            }
            i += 1;
        }

        return pending;
    }

    pub fn draw(self: *PendingProcessesWidget, win: Window) !void {
        const alloc = self.arena.allocator();

        const pending = try self.getPending();
        defer alloc.free(pending);

        var n: u16 = 0;
        var y_off: u16 = 1;
        for (pending, 0..) |process, i| {
            const card = self.cards[i];

            const p = process orelse {
                card.process = null;
                continue;
            };

            try card.updateProcess(self.arena.allocator(), p);
            n += 1;

            const height = card.getHeight();
            const child = win.child(.{ .x_off = @divTrunc(win.width - card.getWidth(), 2), .y_off = y_off, .width = win.width, .height = height });
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
