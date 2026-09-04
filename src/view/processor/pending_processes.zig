const std = @import("std");
const vaxis = @import("vaxis");
const Arena = std.heap.ArenaAllocator;

const Process = @import("~").models.Process.Process;
const Batch = @import("~").models.Batch;
const ExecutionContext = @import("~").models.Context.ExecutionContext;

const Window = vaxis.Window;
const ProcessCardWidget = @import("components/process_card.zig").ProcessCard;

const usize_to = @import("~").utils.usize_to;

const MAX_CARDS_TO_SHOW = Batch.BATCH_SIZE - 1;
pub const PendingProcessesWidget = struct {
    arena: Arena,
    ctx: *ExecutionContext,
    batchIdx: usize,
    cards: []*ProcessCardWidget,

    pub fn init(extern_alloc: std.mem.Allocator, ctx: *ExecutionContext) !*PendingProcessesWidget {
        const self = try extern_alloc.create(PendingProcessesWidget);
        self.arena = Arena.init(extern_alloc);
        self.ctx = ctx;
        self.batchIdx = 0;

        self.cards = try self.arena.allocator().alloc(*ProcessCardWidget, MAX_CARDS_TO_SHOW);
        for (0..self.cards.len) |i| {
            self.cards[i] = try ProcessCardWidget.init(self.arena.allocator());
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

    pub fn updateBatch(self: *PendingProcessesWidget, batchIdx: usize) void {
        self.batchIdx = batchIdx;
        const batch = self.ctx.batches[batchIdx];
        for (0..MAX_CARDS_TO_SHOW) |i| {
            const process = batch[i] orelse continue;
            self.cards[i].updateProcess(self.arena.allocator(), process, batchIdx);
        }
    }

    fn getPending(self: *PendingProcessesWidget) ![]?*Process {
        var pending = try self.arena.allocator().alloc(?*Process, MAX_CARDS_TO_SHOW);
        var i: usize = 0;

        for (&self.ctx.batches[self.batchIdx].queue) |*process| {
            const p: *Process = &(process.* orelse continue);

            if (p.isDone() or std.mem.eql(u8, p.id, self.ctx.current_process_id)) {
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
        const CARD_SPACE = 5;

        const pending = try self.getPending();
        defer self.arena.allocator().free(pending);

        var i: usize = 0;

        for (pending) |process| {
            const p = process orelse break;

            const card = self.cards[i];
            try card.updateProcess(self.arena.allocator(), p, self.batchIdx);

            const child = win.child(.{ .x_off = 0, .y_off = usize_to(i17, CARD_SPACE * i), .width = win.width, .height = CARD_SPACE });
            card.*.draw(child);
            i += 1;
        }
        for (i..self.cards.len) |_| {
            self.cards[i].process = null;
            i += 1;
        }
    }
};
