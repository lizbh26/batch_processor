const std = @import("std");
const vaxis = @import("vaxis");
const Arena = std.heap.ArenaAllocator;

const models = @import("~").models;
const ExecutionContext = models.Context.ExecutionContext;
const Process = models.Process.Process;

const Window = vaxis.Window;
const Label = @import("../components/label.zig").LabelWidget;
const ProcessCardWidget = @import("components/process_card.zig").ProcessCard;

const usize_to = @import("~").utils.usize_to;

const ProcessShorthand = struct { p: *Process, b: usize };

pub const CompletedProcessesWidget = struct {
    arena: Arena,
    ctx: *ExecutionContext,

    title: *Label,
    cards: []*ProcessCardWidget,

    pub fn init(extern_alloc: std.mem.Allocator, ctx: *ExecutionContext) !*CompletedProcessesWidget {
        const self = try extern_alloc.create(CompletedProcessesWidget);
        self.arena = Arena.init(extern_alloc);
        self.ctx = ctx;

        const alloc = self.arena.allocator();

        self.title = try Label.init(alloc);
        self.cards = try alloc.alloc(*ProcessCardWidget, self.ctx.process_count);

        for (0..self.cards.len) |i| {
            self.cards[i] = try ProcessCardWidget.init(alloc, .completed);
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
        var completed = try self.arena.allocator().alloc(?ProcessShorthand, self.ctx.current_process_idx);
        var head: usize = 0;

        const batches = self.ctx.batches.len;

        mainLoop: for (0..batches) |i| {
            const batchIdx = batches - i - 1;
            const batch = &self.ctx.batches[batchIdx];
            const processes = batch.queue.len;

            for (0..processes) |j| {
                const processIdx = processes - j - 1;
                const process = &(batch.queue[processIdx] orelse continue);
                if (process.isDone()) {
                    completed[head] = .{ .p = process, .b = batchIdx };
                    head += 1;
                    if (head >= completed.len) break :mainLoop;
                }
            }
        }

        while (head < completed.len) {
            completed[head] = null;
            head += 1;
        }

        return completed;
    }

    pub fn draw(self: *CompletedProcessesWidget, win: Window) !void {
        const alloc = self.arena.allocator();

        const processes = try self.getLatestCompleted();
        defer alloc.free(processes);

        const plural_S = if (self.ctx.current_process_idx == 1) "" else "s";
        const msg: []const u8 = if (self.ctx.isComplete()) "Todos los procesos terminados" else try std.fmt.allocPrint(alloc, "{d} proceso{s} terminado{s}", .{ self.ctx.current_process_idx, plural_S, plural_S });
        try self.title.changeText(msg);

        const titleWidth = usize_to(u16, self.title.getWidth());
        const titleChild = win.child(.{ .x_off = @divTrunc(win.width - titleWidth, 2), .y_off = 0, .width = titleWidth, .height = 1 });
        self.title.draw(titleChild);

        var i: usize = 0;
        var y_off: u16 = 1;

        for (processes) |process| {
            const card = self.cards[i];
            if (process == null) {
                break;
            }
            try card.updateProcess(alloc, process.?.p, process.?.b);

            const height = card.getHeight();
            const child = win.child(.{ .x_off = @divTrunc((win.width - card.getWidth()), 2), .y_off = y_off, .width = card.getWidth(), .height = height });
            card.draw(child);

            i += 1;
            y_off += height;
        }
        for (i..self.cards.len) |_| {
            self.cards[i].process = null;
        }
    }
};
