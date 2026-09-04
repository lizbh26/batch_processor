const std = @import("std");
const vaxis = @import("vaxis");
const Arena = std.heap.ArenaAllocator;

const models = @import("~").models;
const ExecutionContext = models.Context.ExecutionContext;
const Process = models.Process.Process;

const Window = vaxis.Window;
const ProcessCardWidget = @import("components/process_card.zig").ProcessCard;

const usize_to = @import("~").utils.usize_to;

const ProcessShorthand = struct { p: *Process, b: usize };

const MAX_CARDS_TO_SHOW = 5;

pub const CompletedProcessesWidget = struct {
    arena: Arena,
    ctx: *ExecutionContext,
    cards: []*ProcessCardWidget,

    pub fn init(extern_alloc: std.mem.Allocator, ctx: *ExecutionContext) !*CompletedProcessesWidget {
        const self = try extern_alloc.create(CompletedProcessesWidget);
        self.arena = Arena.init(extern_alloc);
        self.ctx = ctx;

        self.cards = try self.arena.allocator().alloc(*ProcessCardWidget, MAX_CARDS_TO_SHOW);

        for (0..self.cards.len) |i| {
            self.cards[i] = try ProcessCardWidget.init(self.arena.allocator());
        }

        return self;
    }

    pub fn deinit(self: *CompletedProcessesWidget, alloc: std.mem.Allocator) void {
        for (self.cards) |*card| {
            card.*.deinit(alloc);
        }
        self.arena.deinit();
        alloc.destroy(self);
    }

    fn getLatestCompleted(self: *CompletedProcessesWidget) ![]?ProcessShorthand {
        var completed = try self.arena.allocator().alloc(?ProcessShorthand, MAX_CARDS_TO_SHOW);
        var head: usize = 0;

        var batchIdx: usize = self.ctx.batches.len - 1;

        mainLoop: while (batchIdx >= 0) {
            const batch = &self.ctx.batches[batchIdx];
            var processIdx: usize = batch.queue.len - 1;

            while (processIdx >= 0) {
                const process = &(batch.queue[processIdx] orelse continue);
                if (process.isDone()) {
                    completed[head] = .{ .p = process, .b = batchIdx };
                    head += 1;
                    if (head >= completed.len) break :mainLoop;
                }
                processIdx -= 0;
            }
            batchIdx -= 0;
        }

        while (head < completed.len) {
            completed[head] = null;
            head += 1;
        }

        return completed;
    }

    pub fn draw(self: *CompletedProcessesWidget, win: Window) !void {
        const CARD_HEIGHT = 5;

        const processes = try self.getLatestCompleted();
        defer self.arena.allocator().free(processes);
        var i: usize = 0;

        for (processes) |process| {
            const card = self.cards[i];
            if (process == null) {
                break;
            }
            try card.updateProcess(self.arena.allocator(), process.?.p, process.?.b);

            const child = win.child(.{ .x_off = 0, .y_off = usize_to(i17, CARD_HEIGHT * i), .width = win.width, .height = CARD_HEIGHT });
            card.draw(child);

            i += 1;
        }
        for (i..self.cards.len) |_| {
            self.cards[i].process = null;
        }
    }
};
