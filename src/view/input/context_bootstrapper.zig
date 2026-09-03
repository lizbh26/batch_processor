const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;

const Arena = std.heap.ArenaAllocator;
const usize_to = @import("~").utils.usize_to;

const models = @import("~").models;
const ExecutionContext = models.Context.ExecutionContext;

const InputList = @import("components/input_list.zig");
const Input = @import("components/input_with_label.zig");

const inputs = [_]Input.WidgetConfig{
    .{ .label = "Número de procesos", .maxInputSize = 20, .type = .number, .validatorFn = null },
};

pub const ContextBootstrapperWidget = struct {
    arena: Arena,
    inputList: *InputList.InputListWidget,

    isDone: bool,

    pub fn init(extern_alloc: std.mem.Allocator) !*ContextBootstrapperWidget {
        const self = try extern_alloc.create(ContextBootstrapperWidget);
        errdefer extern_alloc.destroy(self);

        self.arena = Arena.init(extern_alloc);
        errdefer self.arena.deinit();

        const our_alloc = self.arena.allocator();

        self.inputList = try InputList.InputListWidget.init(&.{ .alloc = our_alloc, .maxLabelSize = 20, .inputs = &inputs });

        self.isDone = false;

        return self;
    }

    pub fn deinit(self: *ContextBootstrapperWidget, alloc: std.mem.Allocator) void {
        self.arena.deinit(); // Frees all child widgets and buffers
        alloc.destroy(self); // Frees the widget struct itself
    }

    pub fn handle_input(self: *ContextBootstrapperWidget, key: vaxis.Key) !void {
        try self.inputList.handle_input(key);
    }

    pub fn draw(self: *ContextBootstrapperWidget, win: Window) !void {
        if (self.inputList.isDone) self.isDone = true;

        try self.inputList.draw(win);
    }

    pub fn extractContext(self: *ContextBootstrapperWidget, extern_alloc: std.mem.Allocator) !*ExecutionContext {
        const processCountInput = self.inputList.getInputAt(0);

        return try (ExecutionContext).init(extern_alloc, std.fmt.parseInt(u16, processCountInput, 10) catch 0, "lmao");
    }
};
