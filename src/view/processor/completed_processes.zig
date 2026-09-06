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

pub const CompletedProcessesWidget = struct {
    arena: Arena,
    ctx: *ExecutionContext,

    title: Label,
    cards: []ProcessCardWidget,
    cardOffset: u16,

    pub fn init(self: *CompletedProcessesWidget, extern_alloc: std.mem.Allocator, ctx: *ExecutionContext) void {
        self.ctx = ctx;

        self.arena = Arena.init(extern_alloc);
        const alloc = self.arena.allocator();

        self.title.init(alloc);
        self.cardOffset = 0;
    }

    pub fn deinit(self: *CompletedProcessesWidget, alloc: std.mem.Allocator) void {
        for (self.cards) |*card| {
            card.*.deinit(alloc);
        }
        self.arena.deinit();
    }

    pub fn run(self: *CompletedProcessesWidget) !void {
        const alloc = self.arena.allocator();
        self.cards = try alloc.alloc(ProcessCardWidget, self.ctx.process_count);

        for (0..self.cards.len) |i| {
            self.cards[i].init(alloc, .completed);
        }
    }

    pub fn handleInput(self: *CompletedProcessesWidget, key: vaxis.Key) void {
        if (key.matches(vaxis.Key.down, .{})) {
            if (self.ctx.current_process_idx - self.cardOffset > 1) self.cardOffset += 1;
        } else if (key.matches(vaxis.Key.up, .{})) {
            if (self.cardOffset > 0) self.cardOffset -= 1;
        }
    }

    fn getCompleted(self: *CompletedProcessesWidget, alloc: std.mem.Allocator) ![]?*Process {
        const total = self.ctx.process_count;
        var completed = try alloc.alloc(?*Process, total);
        for (self.cardOffset..total) |i| {
            const process = try self.ctx.getProcessWithGlobalIdx(usize_to(u16, i));
            completed[i] = if (process.isDone()) process else null;
        }

        return completed;
    }

    pub fn draw(self: *CompletedProcessesWidget, win: Window) !void {
        const alloc = self.arena.allocator();

        const plural_S = if (self.ctx.current_process_idx == 1) "" else "s";
        const msg: []const u8 = if (self.ctx.isComplete()) "Todos los procesos terminados" else try std.fmt.allocPrint(alloc, "{d} proceso{s} terminado{s}", .{ self.ctx.current_process_idx, plural_S, plural_S });
        try self.title.changeText(msg);

        const titleWidth = usize_to(u16, self.title.getWidth());
        const titleChild = win.child(.{ .x_off = @divTrunc(win.width - titleWidth, 2), .y_off = 0, .width = titleWidth, .height = 1 });
        self.title.draw(titleChild);

        const processes = try self.getCompleted(alloc);
        defer alloc.free(processes);

        var y_off: u16 = 1;
        for (self.cardOffset..self.ctx.process_count) |i| {
            const card = &self.cards[i];
            const p = processes[i] orelse {
                card.process = null;
                continue;
            };

            try card.updateProcess(p);

            const width = card.getWidth(win);
            const height = card.getHeight();
            const child = win.child(.{ .x_off = @divTrunc((win.width - width), 2), .y_off = y_off, .width = width, .height = height });
            card.draw(child);

            y_off += height;
        }
    }
};
