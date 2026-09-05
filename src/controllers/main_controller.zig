const std = @import("std");
const vaxis = @import("vaxis");
const zeit = @import("zeit");

// Vaxis event type
const Event = union(enum) { key_press: vaxis.Key, winsize: vaxis.Winsize, focus_in };

const MainOrchestrator = @import("../view/main_orchestrator.zig").MainOrchestrator;
const mockCtxInit = @import("../view/processor/_utils/mock_ctx.zig").createMockContext;

const FRAME_DURATION: zeit.Duration = .{ .microseconds = 16667 }; //60 FPS or 16 ms per frame

pub const Controller = struct {
    arena: std.heap.ArenaAllocator,
    io: std.Io,

    buffer: [1024]u8,
    tty: vaxis.Tty,
    vx: vaxis.Vaxis,
    loop: vaxis.Loop(Event),

    orchestrator: *MainOrchestrator,

    pub fn init(self: *Controller, init_p: *const std.process.Init) !void {
        self.io = init_p.io;

        self.arena = std.heap.ArenaAllocator.init(init_p.gpa);
        const alloc = self.arena.allocator();

        // Initialize a tty
        self.buffer = undefined;
        self.tty = try vaxis.Tty.init(self.io, &self.buffer);
        errdefer self.tty.deinit();

        self.vx = try vaxis.init(self.io, alloc, init_p.environ_map, .{
            .kitty_keyboard_flags = .{ .report_events = true },
        });

        errdefer self.vx.deinit(alloc, self.tty.writer());

        self.loop = .init(self.io, &self.tty, &self.vx);

        self.orchestrator = try MainOrchestrator.init(alloc);
    }

    pub fn deinit(self: *Controller) void {
        self.vx.deinit(self.arena.allocator(), self.tty.writer());
        self.tty.deinit();
        self.arena.deinit();
    }

    pub fn start_loop(self: *Controller) !void {
        try self.loop.start();
        defer self.loop.stop();

        const alloc = self.arena.allocator();
        const writer = self.tty.writer();

        try self.vx.enterAltScreen(writer);
        try self.vx.setMouseMode(writer, true);

        // Sends queries to terminal to detect certain features. This should
        // _always_ be called, but is left to the application to decide when
        try self.vx.queryTerminal(writer, .fromSeconds(1));

        var frameStart = zeit.instant(.{ .now = self.io }, &zeit.utc);
        var now = frameStart;

        try self.orchestrator.switchToProcessorPhase(try mockCtxInit(alloc, 8), now);

        // The main event loop. Vaxis provides a thread safe, blocking, buffered
        // queue which can serve as the primary event queue for an application
        while (true) {
            now = zeit.instant(.{ .now = self.io }, &zeit.utc);

            const event = try self.loop.tryEvent();
            if (event != null) {
                switch (event.?) {
                    .key_press => |key| {
                        if (key.matches('c', .{ .ctrl = true })) {
                            break;
                        } else if (key.matches('l', .{ .ctrl = true })) {
                            self.vx.queueRefresh();
                        } else {
                            try self.orchestrator.handleInput(key);
                        }
                    },

                    .winsize => |ws| {
                        try self.vx.resize(alloc, writer, ws);
                        self.vx.refresh = true;
                    },
                    else => {},
                }
            } else {
                const diffFromCurrFrame = now.timestamp - frameStart.timestamp;
                const totalFrameDiff = FRAME_DURATION.inNanoseconds() catch unreachable;

                const sleepNanos: i96 = @intCast(totalFrameDiff - diffFromCurrFrame);
                if (sleepNanos > 0) try std.Io.sleep(self.io, .{ .nanoseconds = sleepNanos }, .awake);

                frameStart = zeit.instant(.{ .now = self.io }, &zeit.utc);
            }

            try self.orchestrator.tick(now);

            // vx.window() returns the root window. This window is the size of the
            // terminal and can spawn child windows as logical areas. Child windows
            // cannot draw outside of their bounds
            const win = self.vx.window();

            // Clear the entire space because we are drawing in immediate mode.
            // vaxis double buffers the screen. This new frame will be compared to
            // the old and only updated cells will be drawn
            win.clear();

            try self.orchestrator.draw(win);

            win.hideCursor();

            try self.vx.render(writer);
            try writer.flush();
        }
    }
};
