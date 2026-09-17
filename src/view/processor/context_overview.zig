const std = @import("std");
const vaxis = @import("vaxis");
const Arena = std.heap.ArenaAllocator;

const models = @import("~").models;
const ExecutionContext = models.Context.ExecutionContext;
const Process = models.Process.Process;

const Window = vaxis.Window;
const Label = @import("../components/label.zig").LabelWidget;
const ProcessStripWidget = @import("components/process_strip.zig").ProcessStripWidget;

const usize_to = @import("~").utils.usize_to;

pub const ContextOverviewWidget = struct {
    const Self = @This();

    arena: Arena,
    ctx: *ExecutionContext,

    title: Label,
    strips: []ProcessStripWidget,
    offset: u16,

    pub fn init(self: *Self, extern_alloc: std.mem.Allocator, ctx: *ExecutionContext) void {
        self.arena = Arena.init(extern_alloc);
        const alloc = self.arena.allocator();

        self.ctx = ctx;

        self.title.init(alloc);
        self.title.changeText("Vista resumida") catch unreachable;
        self.offset = 0;
    }

    pub fn deinit(self: *Self, alloc: std.mem.Allocator) void {
        for (self.strips) |*strip| {
            strip.deinit(alloc);
        }
        self.arena.deinit();
    }

    pub fn kickstart(self: *Self) !void {
        const alloc = self.arena.allocator();
        self.strips = try alloc.alloc(ProcessStripWidget, self.ctx.process_count);

        for (self.strips) |*strip| {
            strip.init(alloc);
        }
    }

    pub fn handleInput(self: *Self, key: vaxis.Key) void {
        if (key.matches(vaxis.Key.down, .{})) {
            if (self.ctx.process_count - self.offset > 1) self.offset += 1;
        } else if (key.matches(vaxis.Key.up, .{})) {
            if (self.offset > 0) self.offset -= 1;
        }
    }

    pub fn update(self: *Self) !void {
        var strip_idx: usize = 0;
        for (0..self.ctx.finished_queue.len) |i| {
            const p = self.ctx.finished_queue.get(i) catch break;
            try self.strips[strip_idx].update(p, .finalized);
            strip_idx += 1;
        }
    }

    pub fn draw(self: *Self, win: Window) !void {
        const titleWidth = usize_to(u16, self.title.getWidth());
        const titleChild = win.child(.{ .x_off = @divTrunc(win.width - titleWidth, 2), .y_off = 0, .width = titleWidth, .height = 1 });
        self.title.draw(titleChild);

        const stripsContainer = win.child(.{ .y_off = 2, .height = win.height - 2 });
        var y_off: u16 = 0;
        for (self.offset..self.strips.len) |i| {
            const strip = &self.strips[i];

            const dim = strip.getDimensions(stripsContainer);
            const height = dim.rows + 1;
            const child = stripsContainer.child(.{ .y_off = y_off, .height = height });
            strip.draw(child);

            y_off += height + 1;

            if (y_off > win.height) break;
        }
    }
};
