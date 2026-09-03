const std = @import("std");
const vaxis = @import("vaxis");
const Arena = std.heap.ArenaAllocator;

const Batch = @import("~").models.Batch;

const Window = vaxis.Window;
const ProcessCardWidget = @import("components/process_card.zig").ProcessCard;

const usize_to = @import("~").utils.usize_to;

pub const PendingProcessesWidget = struct {
    arena: Arena,
    batch: *Batch.Batch,
    cards: []*ProcessCardWidget,

    pub fn init(extern_alloc: std.mem.Allocator, batch: *Batch.Batch) !*PendingProcessesWidget {
        const self = try extern_alloc.create(PendingProcessesWidget);
        self.arena = Arena.init(extern_alloc);
        self.batch = batch;

        var processCount: usize = 0;
        for (self.batch.queue) |process| {
            if (process != null) processCount += 1;
        }
        self.cards = try self.arena.allocator().alloc(*ProcessCardWidget, processCount);

        for (0..self.cards.len) |i| {
            var process = self.batch.queue[i] orelse continue;
            self.cards[i] = try ProcessCardWidget.init(self.arena.allocator(), &process);
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

    pub fn updateBatch(self: *PendingProcessesWidget, batch: *Batch.Batch) void {
        self.batch = batch;
        for (self.cards, 0..) |card, i| {
            card.updateProcess(batch[i]);
        }
    }

    pub fn draw(self: *PendingProcessesWidget, win: Window) !void {
        const CARD_SPACE = 5;
        for (self.cards, 0..) |*card, i| {
            const child = win.child(.{ .x_off = 0, .y_off = usize_to(i17, CARD_SPACE * i), .width = win.width, .height = CARD_SPACE });
            card.*.draw(child);
        }
    }
};
