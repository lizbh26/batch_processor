const std = @import("std");
const ExecutionContext = @import("~").models.Context.ExecutionContext;

pub fn createMockContext(alloc: std.mem.Allocator) !*ExecutionContext {
    const ctx = try ExecutionContext.init(alloc, 8, "Test User");
    for (ctx.batches) |*batch| {
        for (batch) |*process| {
            process.seed();
        }
    }
    return ctx;
}
