const std = @import("std");
const zeit = @import("zeit");
const vaxis = @import("vaxis");

const ExecutionContext = @import("~").models.Context.ExecutionContext;

const Window = vaxis.Window;
const InputOrchestratorWidget = @import("input/input_orchestrator.zig").InputOrchestratorWidget;
const ProcessorOrchestratorWidget = @import("processor/processor_orchestrator.zig").ProcessorOrchestratorWidget;

pub const MainOrchestrator = struct {
    arena: std.heap.ArenaAllocator,

    phase: enum { input, processor },

    inputOrchestrator: *InputOrchestratorWidget,
    processorOrchestrator: *ProcessorOrchestratorWidget,

    pub fn init(extern_alloc: std.mem.Allocator) !*MainOrchestrator {
        const self = try extern_alloc.create(MainOrchestrator);
        errdefer extern_alloc.destroy(self);

        self.arena = std.heap.ArenaAllocator.init(extern_alloc);
        const alloc = self.arena.allocator();

        self.inputOrchestrator = try InputOrchestratorWidget.init(alloc);
        errdefer self.inputOrchestrator.deinit(alloc);

        self.processorOrchestrator = undefined;
        self.phase = .input;

        return self;
    }

    pub fn deinit(self: *MainOrchestrator, alloc: std.mem.Allocator) void {
        self.arena.deinit();
        alloc.destroy(self);
    }

    pub fn switchToProcessorPhase(self: *MainOrchestrator, ctx: *ExecutionContext, now: zeit.Instant) !void {
        const alloc = self.arena.allocator();
        self.processorOrchestrator = try ProcessorOrchestratorWidget.init(alloc, ctx, now);
        self.inputOrchestrator.deinit(alloc);
        self.phase = .processor;
    }

    pub fn handleInput(self: *MainOrchestrator, key: vaxis.Key) !void {
        switch (self.phase) {
            .input => try self.inputOrchestrator.handle_input(key),
            else => {},
        }
    }

    pub fn tick(self: *MainOrchestrator, now: zeit.Instant) !void {
        switch (self.phase) {
            .processor => try self.processorOrchestrator.tick(now),
            else => {},
        }
    }

    pub fn draw(self: *MainOrchestrator, win: vaxis.Window) !void {
        switch (self.phase) {
            .input => try self.inputOrchestrator.draw(win),
            .processor => try self.processorOrchestrator.draw(win),
        }
    }
};
