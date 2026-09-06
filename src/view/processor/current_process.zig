const std = @import("std");
const zeit = @import("zeit");
const vaxis = @import("vaxis");
const Arena = std.heap.ArenaAllocator;

const models = @import("~").models;
const ExecutionContext = models.Context.ExecutionContext;
const Process = models.Process.Process;

const Window = vaxis.Window;
const ProcessCardWidget = @import("components/process_card.zig").ProcessCard;
const Label = @import("../components/label.zig").LabelWidget;

const usize_to = @import("~").utils.usize_to;

pub const CurrentProcessExecutionWidget = struct {
    arena: Arena,
    ctx: *ExecutionContext,
    time_start: zeit.Instant,

    title: Label,
    card: ProcessCardWidget,

    running: bool,

    pub fn init(self: *CurrentProcessExecutionWidget, extern_alloc: std.mem.Allocator, ctx: *ExecutionContext) void {
        self.arena = Arena.init(extern_alloc);
        const alloc = self.arena.allocator();

        self.ctx = ctx;
        self.title.init(alloc);
        self.card.init(alloc, .doing);
        self.running = false;
    }
    pub fn deinit(self: *CurrentProcessExecutionWidget, alloc: std.mem.Allocator) void {
        self.arena.deinit();
        alloc.destroy(self);
    }

    pub fn run(self: *CurrentProcessExecutionWidget, now: zeit.Instant) void {
        self.time_start = now;
        self.running = true;
    }

    pub fn tick(self: *CurrentProcessExecutionWidget, now: zeit.Instant) void {
        if (!self.running or self.ctx.isComplete()) return;

        const timeEllapsedNano = now.timestamp - self.time_start.timestamp;
        const diff = zeit.instant(.{ .unix_nano = timeEllapsedNano }, &zeit.utc).milliTimestamp();

        const process = self.ctx.getCurrentProcess();
        process.tt_ms = diff;

        if (process.isDone()) {
            self.ctx.moveToNextProcess();
            self.time_start = now;
        }
    }
    pub fn draw(self: *CurrentProcessExecutionWidget, win: Window) !void {
        const alloc = self.arena.allocator();

        const msg: []const u8 = if (self.ctx.isComplete()) "Sin procesos a ejecutar" else try std.fmt.allocPrint(alloc, "Proceso en ejecución: {s}", .{self.ctx.getCurrentProcess().id});
        try self.title.changeText(msg);

        const titleWidth = usize_to(u16, self.title.getWidth());
        const titleChild = win.child(.{ .x_off = usize_to(i17, @divTrunc((win.width - titleWidth), 2)), .y_off = 0, .width = titleWidth, .height = 1 });
        self.title.draw(titleChild);

        if (!self.ctx.isComplete()) {
            try self.card.updateProcess(self.ctx.getCurrentProcess());
            const cardChild = win.child(.{ .x_off = @divTrunc(win.width - self.card.getWidth(win), 2), .y_off = 1, .width = win.width - 2, .height = self.card.getHeight() });
            self.card.draw(cardChild);
        }
    }
};
