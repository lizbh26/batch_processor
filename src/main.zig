const std = @import("std");
const vaxis = @import("vaxis");

const Event = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
    focus_in,
};

const InputOrchestratorWidget = @import("view/input/input_orchestrator.zig").InputOrchestratorWidget;
const ProcessorOrchestratorWidget = @import("view/processor/processor_orchestrator.zig").ProcessorOrchestratorWidget;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const alloc = init.gpa;

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

    const orchestrator = try ProcessorOrchestratorWidget.init(alloc);
    defer orchestrator.deinit(alloc);

    // The main event loop. Vaxis provides a thread safe, blocking, buffered
    // queue which can serve as the primary event queue for an application
    while (true) {
        // nextEvent blocks until an event is in the queue
        const event = try loop.nextEvent();
        // log.debug("event: {}", .{event});
        // exhaustive switching ftw. Vaxis will send events if your Event
        // enum has the fields for those events (ie "key_press", "winsize")
        switch (event) {
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true })) {
                    break;
                } else if (key.matches('l', .{ .ctrl = true })) {
                    vx.queueRefresh();
                } else {
                    try orchestrator.handle_input(key);
                }
            },

            .winsize => |ws| try vx.resize(alloc, tty.writer(), ws),
            else => {},
        }

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
