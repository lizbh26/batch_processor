const std = @import("std");

const Controller = @import("controller.zig");

pub fn main(init: std.process.Init) !void {
    var controller: Controller.Controller = undefined;
    try controller.init(&init);
    defer controller.deinit();

    controller.startLoop() catch |err| switch (err) {
        error.TerminalSize => std.log.err("Tu terminal es demasiado pequeña o no es soportada por este programa; el tamaño mínimo es {d}x{d}", .{ Controller.MIN_SCREEN_WIDTH, Controller.MIN_SCREEN_HEIGHT }),
        else => std.log.err("Ocurrio un error inesperado.", .{}),
    };
}
