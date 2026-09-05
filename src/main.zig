const std = @import("std");

const Controller = @import("controllers/main_controller.zig").Controller;

pub fn main(init: std.process.Init) !void {
    var controller: Controller = undefined;
    try controller.init(&init);
    defer controller.deinit();

    try controller.start_loop();
}
