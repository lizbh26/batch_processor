const std = @import("std");
const Batch = @import("batch.zig");

pub const ExecutionContext = struct {
    batches: []Batch.Batch,
    process_count: u16,
    user_name: []const u8,
    current_process_id: []const u8,

    pub fn init(alloc: std.mem.Allocator, count: u16, user_name: []const u8) !*ExecutionContext {
        const self = try alloc.create(ExecutionContext);

        self.batches = try alloc.alloc(Batch.Batch, (count / Batch.BATCH_SIZE) + 1);
        self.process_count = count;
        self.user_name = user_name;
        self.current_process_id = "";

        return self;
    }

    pub fn deinit(self: *ExecutionContext, alloc: std.mem.Allocator) void {
        alloc.free(self.batches);
        alloc.destroy(self);
    }
};
