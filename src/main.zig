const std = @import("std");
const vaxis = @import("vaxis");
const zeit = @import("zeit");

const Event = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
    focus_in,
};

const InputOrchestratorWidget = @import("view/input/input_orchestrator.zig").InputOrchestratorWidget;
const ProcessorOrchestratorWidget = @import("view/processor/processor_orchestrator.zig").ProcessorOrchestratorWidget;

const mockCtxInit = @import("view/processor/_utils/mock_ctx.zig").createMockContext;

const FRAME_DURATION: zeit.Duration = .{ .microseconds = 16667 }; //60 FPS

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const global_alloc = init.gpa;

    var global_arena = std.heap.ArenaAllocator.init(global_alloc);
    defer global_arena.deinit();
    const alloc = global_arena.allocator();

    // Initialize a tty
    var buffer: [1024]u8 = undefined;
    var tty = try vaxis.Tty.init(io, &buffer);
    defer tty.deinit();
    const writer = tty.writer();

    var vx = try vaxis.init(io, alloc, init.environ_map, .{
        .kitty_keyboard_flags = .{ .report_events = true },
    });
    defer vx.deinit(alloc, tty.writer());

    var loop: vaxis.Loop(Event) = .init(io, &tty, &vx);

    try loop.start();
    defer loop.stop();

    try vx.enterAltScreen(writer);
    try vx.setMouseMode(writer, true);

    // Sends queries to terminal to detect certain features. This should
    // _always_ be called, but is left to the application to decide when
    try vx.queryTerminal(tty.writer(), .fromSeconds(1));

    const mockCtx = try mockCtxInit(alloc, 8);
    defer mockCtx.deinit(alloc);

    const orchestrator = try ProcessorOrchestratorWidget.init(alloc, io, mockCtx);
    defer orchestrator.deinit(alloc);

    var frameStart = zeit.instant(.{ .now = init.io }, &zeit.utc);
    var now = frameStart;

    // The main event loop. Vaxis provides a thread safe, blocking, buffered
    // queue which can serve as the primary event queue for an application
    while (true) {
        now = zeit.instant(.{ .now = init.io }, &zeit.utc);

        const event = try loop.tryEvent();
        if (event != null) {
            switch (event.?) {
                .key_press => |key| {
                    if (key.matches('c', .{ .ctrl = true })) {
                        break;
                    } else if (key.matches('l', .{ .ctrl = true })) {
                        vx.queueRefresh();
                    } else {
                        try orchestrator.handle_input(key);
                    }
                },

                .winsize => |ws| {
                    try vx.resize(alloc, tty.writer(), ws);
                    vx.refresh = true;
                },
                else => {},
            }
        } else {
            const diffFromCurrFrame = now.timestamp - frameStart.timestamp;
            const totalFrameDiff = FRAME_DURATION.inNanoseconds() catch unreachable;

            const sleepNanos: i96 = @intCast(totalFrameDiff - diffFromCurrFrame);
            if (sleepNanos > 0) try std.Io.sleep(init.io, .{ .nanoseconds = sleepNanos }, .awake);

            frameStart = zeit.instant(.{ .now = init.io }, &zeit.utc);
        }

        try orchestrator.tick(now);

        // vx.window() returns the root window. This window is the size of the
        // terminal and can spawn child windows as logical areas. Child windows
        // cannot draw outside of their bounds
        const win = vx.window();

        // Clear the entire space because we are drawing in immediate mode.
        // vaxis double buffers the screen. This new frame will be compared to
        // the old and only updated cells will be drawn
        win.clear();

        try orchestrator.draw(win);

        win.hideCursor();

        try vx.render(writer);
        try writer.flush();
    }
}
