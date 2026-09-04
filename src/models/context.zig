const std = @import("std");
const Batch = @import("batch.zig");
const Process = @import("process.zig").Process;

pub const ExecutionContext = struct {
    batches: []Batch.Batch,
    process_count: u16,
    user_name: []const u8,

    current_process_idx: u16,

    pub fn init(alloc: std.mem.Allocator, count: u16, user_name: []const u8) !*ExecutionContext {
        const self = try alloc.create(ExecutionContext);

        self.batches = try alloc.alloc(Batch.Batch, (count / Batch.BATCH_SIZE) + 1);
        self.process_count = count;
        self.user_name = user_name;
        self.current_process_idx = 0;

        return self;
    }

    pub fn deinit(self: *ExecutionContext, alloc: std.mem.Allocator) void {
        alloc.free(self.batches);
        alloc.destroy(self);
    }

    pub fn getBatchAndProcessIdx(self: *ExecutionContext) struct { u16, u16 } {
        var batchIdx: u16 = 0;
        var processIdx: u16 = self.current_process_idx;
        while (processIdx >= Batch.BATCH_SIZE) {
            processIdx -= Batch.BATCH_SIZE;
            batchIdx += 1;
        }
        return .{ batchIdx, processIdx };
    }

    pub fn getCurrentProcess(self: *ExecutionContext) *Process {
        const batchIdx, const processIdx = self.getBatchAndProcessIdx();
        return &self.batches[batchIdx].queue[processIdx].?;
    }
    pub fn isComplete(self: *ExecutionContext) bool {
        return self.process_count == self.current_process_idx;
    }
};
