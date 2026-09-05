const std = @import("std");
const Batch = @import("batch.zig");
const Process = @import("process.zig").Process;

pub const ExecutionContext = struct {
    arena: std.heap.ArenaAllocator,

    batches: []Batch.Batch,
    process_count: u16,

    current_process_idx: u16,

    pub fn init(self: *ExecutionContext, extern_alloc: std.mem.Allocator) void {
        self.arena = std.heap.ArenaAllocator.init(extern_alloc);
        self.process_count = 0;
        self.current_process_idx = 0;
    }
    pub fn deinit(self: *ExecutionContext) void {
        self.arena.deinit();
    }

    pub fn createBatches(self: *ExecutionContext, pCount: u16) !void {
        const alloc = self.arena.allocator();

        var batchIdx, const leftoverProcessCount = self.getBatchAndProcessIdxForGlobalIdx(pCount);
        if (leftoverProcessCount > 0) batchIdx += 1;
        self.batches = try alloc.alloc(Batch.Batch, batchIdx);
        for (0..Batch.BATCH_SIZE - leftoverProcessCount) |i| {
            self.batches[batchIdx - 1].queue[Batch.BATCH_SIZE - i - 1] = null;
        }

        self.process_count = pCount;
        self.current_process_idx = 0;
    }

    fn getBatchAndProcessIdxForGlobalIdx(_: *ExecutionContext, idx: u16) struct { u16, u16 } {
        var batchIdx: u16 = 0;
        var processIdx: u16 = idx;
        while (processIdx >= Batch.BATCH_SIZE) {
            processIdx -= Batch.BATCH_SIZE;
            batchIdx += 1;
        }
        return .{ batchIdx, processIdx };
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
    pub fn moveToNextProcess(self: *ExecutionContext) void {
        self.getCurrentProcess().operation.calculate();
        self.current_process_idx += 1;
    }
    pub fn isComplete(self: *ExecutionContext) bool {
        return self.process_count == self.current_process_idx;
    }
};
