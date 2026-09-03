const std = @import("std");
const Batch = @import("batch.zig");

pub const ExecutionContext = struct {
    batches: []Batch.Batch,
    process_count: u16,
    user_name: []const u8,
    pub fn init(alloc: std.mem.Allocator, count: u16, user_name: []const u8) !*ExecutionContext {
        const self = try alloc.create(ExecutionContext);

        self.batches = try alloc.alloc(Batch.Batch, (count / Batch.BATCH_SIZE) + 1);
        self.process_count = count;
        self.user_name = user_name;

        return self;
    }
};
