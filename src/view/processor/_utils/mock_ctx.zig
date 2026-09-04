const std = @import("std");
const ExecutionContext = @import("~").models.Context.ExecutionContext;

pub fn createMockContext(alloc: std.mem.Allocator, size: u16) !*ExecutionContext {
    const ctx = try ExecutionContext.init(alloc, size, "Test User");
    var i: u16 = 0;

    for (ctx.batches) |*batch| {
        for (&batch.queue) |*process| {
            if (process.* == null) continue;
            if (i < size) {
                process.*.?.seed(alloc, i + 1);
            } else {
                process.* = null;
            }
            i += 1;
        }
    }
    return ctx;
}
