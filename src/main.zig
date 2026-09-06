const std = @import("std");

const Controller = @import("controller.zig").Controller;

pub fn main(init: std.process.Init) !void {
    var controller: Controller = undefined;
    try controller.init(&init);
    defer controller.deinit();

    try controller.startLoop();
}
