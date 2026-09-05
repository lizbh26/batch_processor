const std = @import("std");
const Batch = @import("batch.zig");
const Process = @import("process.zig").Process;

pub const ExecutionContext = struct {
    batches: []Batch.Batch,
    process_count: u16,
    user_name: []const u8,

    current_process_idx: u16,

    fn getBatchAndProcessIdxForGlobalIdx(_: *ExecutionContext, idx: u16) struct { u16, u16 } {
        var batchIdx: u16 = 0;
        var processIdx: u16 = idx;
        while (processIdx >= Batch.BATCH_SIZE) {
            processIdx -= Batch.BATCH_SIZE;
            batchIdx += 1;
        }
        return .{ batchIdx, processIdx };
    }

    pub fn init(alloc: std.mem.Allocator, count: u16, user_name: []const u8) !*ExecutionContext {
        const self = try alloc.create(ExecutionContext);

        var batchCount, const leftoverProcessCount = self.getBatchAndProcessIdxForGlobalIdx(count);
        if (leftoverProcessCount > 0) batchCount += 1;
        self.batches = try alloc.alloc(Batch.Batch, batchCount);
        for (0..leftoverProcessCount) |i| {
            self.batches[batchCount - 1].queue[Batch.BATCH_SIZE - i - 1] = null;
        }

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
        return self.getBatchAndProcessIdxForGlobalIdx(self.current_process_idx);
    }

    pub fn getCurrentBatch(self: *ExecutionContext) *Batch.Batch {
        const batchIdx, _ = self.getBatchAndProcessIdx();
        return &self.batches[batchIdx];
    }
    pub fn getCurrentProcess(self: *ExecutionContext) *Process {
        const batchIdx, const processIdx = self.getBatchAndProcessIdx();
        return &self.batches[batchIdx].queue[processIdx].?;
    }
    pub fn getProcessWithGlobalIdx(self: *ExecutionContext, idx: u16) !*Process {
        if (idx >= self.process_count) return error.OverFlow;
        const batchIdx, const processIdx = self.getBatchAndProcessIdxForGlobalIdx(idx);
        return &self.batches[batchIdx].queue[processIdx].?;
    }
    pub fn isComplete(self: *ExecutionContext) bool {
        return self.process_count == self.current_process_idx;
    }
};
