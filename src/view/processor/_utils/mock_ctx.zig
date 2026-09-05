const std = @import("std");
const ExecutionContext = @import("~").models.Context.ExecutionContext;
const Process = @import("~").models.Process.Process;

pub fn createMockContext(alloc: std.mem.Allocator, size: u16) !*ExecutionContext {
    const ctx = try ExecutionContext.init(alloc, size, "Test User");
    var i: u16 = 0;

    mainLoop: for (ctx.batches, 0..) |*batch, bIdx| {
        for (&batch.queue) |*process| {
            if (i >= size) break :mainLoop;
            const p: *Process = &(process.* orelse unreachable);

            i += 1;
            p.seed(alloc, .{ .id = i, .batchIdx = bIdx });
        }
    }
    return ctx;
}
