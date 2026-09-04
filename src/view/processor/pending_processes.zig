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

    fn getPending(self: *PendingProcessesWidget, batchIdx: u16) ![]?*Process {
        var pending = try self.arena.allocator().alloc(?*Process, MAX_CARDS_TO_SHOW);
        var i: usize = 0;

        for (&self.ctx.batches[batchIdx].queue, 0..) |*process, processIdx| {
            const p: *Process = &(process.* orelse continue);

            const currentBatchIdx, const currentProcessIdx = self.ctx.getBatchAndProcessIdx();
            if (p.isDone() or (batchIdx == currentBatchIdx and processIdx == currentProcessIdx)) {
                continue;
            }

            pending[i] = p;

            i += 1;
            if (i >= pending.len) break;
        }
        while (i < pending.len) {
            pending[i] = null;
            i += 1;
        }

        return pending;
    }

    pub fn draw(self: *PendingProcessesWidget, win: Window) !void {
        const alloc = self.arena.allocator();

        const batchIdx, _ = self.ctx.getBatchAndProcessIdx();

        const pending = try self.getPending(batchIdx);
        defer alloc.free(pending);

        try self.title.changeText(try std.fmt.allocPrint(alloc, "Lote {d} en ejecución", .{batchIdx + 1}));
        const titleWidth = usize_to(u16, self.title.getWidth());
        const titleChild = win.child(.{ .x_off = @divTrunc(win.width - titleWidth, 2), .y_off = 0, .width = titleWidth, .height = 1 });
        self.title.draw(titleChild);

        var i: usize = 0;
        var y_off: u16 = 1;

        for (pending) |process| {
            const p = process orelse break;

            const card = self.cards[i];
            try card.updateProcess(self.arena.allocator(), p, batchIdx);

            const height = card.getHeight();
            const child = win.child(.{ .x_off = @divTrunc(win.width - card.getWidth(), 2), .y_off = y_off, .width = win.width, .height = height });
            card.*.draw(child);
            i += 1;
            y_off += height;
        }
        for (i..self.cards.len) |_| {
            self.cards[i].process = null;
            i += 1;
        }
    }
};
