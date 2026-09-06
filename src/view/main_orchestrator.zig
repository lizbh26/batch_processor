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

    inputOrchestrator: InputOrchestratorWidget,
    processorOrchestrator: ProcessorOrchestratorWidget,

    ctx: ExecutionContext,

    pub fn init(self: *MainOrchestrator, extern_alloc: std.mem.Allocator) void {
        self.arena = std.heap.ArenaAllocator.init(extern_alloc);
        const alloc = self.arena.allocator();

        self.ctx.init(alloc);

        self.inputOrchestrator.init(alloc, &self.ctx);
        self.processorOrchestrator.init(alloc, &self.ctx);

        self.phase = .input;
    }

    pub fn deinit(self: *MainOrchestrator, alloc: std.mem.Allocator) void {
        self.arena.deinit();
        alloc.destroy(self);
    }

    pub fn switchToProcessorPhase(self: *MainOrchestrator, now: zeit.Instant) !void {
        self.ctx.current_process_idx = 0;
        self.phase = .processor;
        try self.processorOrchestrator.run(now);
        self.inputOrchestrator.deinit();
    }

    pub fn handleInput(self: *MainOrchestrator, key: vaxis.Key) !void {
        switch (self.phase) {
            .input => try self.inputOrchestrator.handleInput(key),
            else => {},
        }
    }

    pub fn tick(self: *MainOrchestrator, now: zeit.Instant) !void {
        switch (self.phase) {
            .input => {
                try self.inputOrchestrator.tick();
                if (self.ctx.process_count > 0 and self.ctx.isComplete()) {
                    try self.switchToProcessorPhase(now);
                }
            },
            .processor => try self.processorOrchestrator.tick(now),
        }
    }

    pub fn draw(self: *MainOrchestrator, win: vaxis.Window) !void {
        switch (self.phase) {
            .input => try self.inputOrchestrator.draw(win),
            .processor => try self.processorOrchestrator.draw(win),
        }
    }
};
