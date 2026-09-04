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

    title: *Label,
    card: *ProcessCardWidget,

    running: bool,

    pub fn init(extern_alloc: std.mem.Allocator, ctx: *ExecutionContext) !*CurrentProcessExecutionWidget {
        const self = try extern_alloc.create(CurrentProcessExecutionWidget);
        self.arena = Arena.init(extern_alloc);
        const alloc = self.arena.allocator();

        self.ctx = ctx;
        self.title = try Label.init(alloc);
        self.card = try ProcessCardWidget.init(alloc, .doing);
        self.running = false;

        return self;
    }
    pub fn deinit(self: *CurrentProcessExecutionWidget, alloc: std.mem.Allocator) void {
        self.arena.deinit();
        alloc.destroy(self);
    }

    pub fn start(self: *CurrentProcessExecutionWidget, now: zeit.Instant) void {
        self.time_start = now;
        self.running = true;
    }

    pub fn tick(self: *CurrentProcessExecutionWidget, now: zeit.Instant) void {
        if (!self.running) return;

        const timeEllapsedNano = now.timestamp - self.time_start.timestamp;
        const diff = zeit.instant(.{ .unix_nano = timeEllapsedNano }, &zeit.utc).milliTimestamp();

        const process = self.ctx.getCurrentProcess();
        process.tt_ms = diff;

        if (process.isDone()) {
            self.ctx.current_process_idx += 1;
            self.time_start = now;
        }
    }
    pub fn draw(self: *CurrentProcessExecutionWidget, win: Window) !void {
        try self.title.changeText(try std.fmt.allocPrint(self.arena.allocator(), "Proceso en ejecución: {d}/{d}", .{ self.ctx.current_process_idx, self.ctx.process_count }));
        const titleWidth = usize_to(u16, self.title.getWidth());
        const titleChild = win.child(.{ .x_off = usize_to(i17, @divTrunc((win.width - titleWidth), 2)), .y_off = 0, .width = titleWidth, .height = 1 });
        self.title.draw(titleChild);

        const batchIdx, _ = self.ctx.getBatchAndProcessIdx();
        try self.card.updateProcess(self.arena.allocator(), self.ctx.getCurrentProcess(), batchIdx);
        const cardChild = win.child(.{ .x_off = @divTrunc(win.width - self.card.getWidth(), 2), .y_off = 1, .width = win.width - 2, .height = self.card.getHeight() });
        self.card.draw(cardChild);
    }
};
