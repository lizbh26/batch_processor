const std = @import("std");
const Arena = std.heap.ArenaAllocator;

const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const Window = vaxis.Window;
const Label = @import("../components/label.zig").LabelWidget;

pub const FooterWidget = struct {
    arena: Arena,
    stateControls: Label,
    scrollControls: Label,

    pub fn init(self: *FooterWidget, extern_alloc: std.mem.Allocator) void {
        self.arena = Arena.init(extern_alloc);
        const alloc = self.arena.allocator();

        self.stateControls.init(alloc);
        self.showPausedControls() catch unreachable;

        self.scrollControls.init(alloc);
        self.scrollControls.changeText("🠝/🠟 - Navegar completados") catch unreachable;
    }

    pub fn showRunningControls(self: *FooterWidget) !void {
        try self.stateControls.changeText("P - Pausar simulación    E - Interrumpir programa    W - Fallar programa    Ctrl+C - Salir");
    }
    pub fn showPausedControls(self: *FooterWidget) !void {
        try self.stateControls.changeText("Simulación pausada    C - Continuar");
    }
    pub fn showCompletedControls(self: *FooterWidget) !void {
        try self.stateControls.changeText("Simulación terminada    Ctrl+C - Salir");
    }
    pub fn draw(self: *FooterWidget, win: Window) !void {
        const stateControlsWidth = @min(self.stateControls.getWidth(), win.width);
        const stateControlsChild = win.child(.{ .x_off = 0, .y_off = 0, .width = stateControlsWidth, .height = 1 });
        self.stateControls.draw(stateControlsChild);

        const scrollControlsWidth = @min(self.scrollControls.getWidth(), win.width);
        const scrollControlsChild = win.child(.{ .x_off = win.width - scrollControlsWidth, .y_off = 0, .width = scrollControlsWidth, .height = 1 });
        self.scrollControls.draw(scrollControlsChild);
    }
};
