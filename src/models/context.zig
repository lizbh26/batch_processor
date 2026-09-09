const std = @import("std");
const Batch = @import("batch.zig");
const Process = @import("process.zig").Process;

const usize_to = @import("../utils/index.zig").usize_to;

pub const ExecutionContext = struct {
    arena: std.heap.ArenaAllocator,

    batches: []Batch.Batch,
    current_batch: u16,

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

    pub fn createBatches(self: *ExecutionContext, random: std.Random, pCount: u16) !void {
        const alloc = self.arena.allocator();

        var batches, const remainingProcesses = divideWithRemainder(u16, pCount, Batch.BATCH_SIZE);
        if (remainingProcesses > 0) batches += 1;

        self.batches = try alloc.alloc(Batch.Batch, batches);
        for (self.batches, 0..) |*batch, i| {
            const size = if (remainingProcesses > 0 and i == self.batches.len - 1) remainingProcesses else Batch.BATCH_SIZE;
            batch.seed(
                random,
                size,
                i,
            );
        }

        self.process_count = pCount;
        self.current_batch = 0;
    }

    pub fn getBatchAndProcessIdx(self: *ExecutionContext) struct { u16, u16 } {
        return .{ self.current_batch, self.getCurrentBatch().current };
    }
    pub fn getCurrentBatch(self: *ExecutionContext) *Batch.Batch {
        return &self.batches[self.current_batch];
    }
    pub fn getCurrentProcess(self: *ExecutionContext) *Process {
        return self.getCurrentBatch().getCurrent() catch unreachable;
    }
    pub fn getCompletedProcesses(self: *ExecutionContext) u16 {
        var pCount: u16 = 0;
        for (0..self.current_batch) |i| pCount += self.batches[i].done;
        if (!self.isComplete()) pCount += self.getCurrentBatch().done;
        return pCount;
    }
    pub fn getProcessWithGlobalIdx(self: *ExecutionContext, idx: u16) !*Process {
        if (idx > self.process_count) return error.OverFlow;
        const batchIdx, const processIdx = divideWithRemainder(u16, idx, Batch.BATCH_SIZE);
        return &(self.batches[batchIdx].queue[processIdx].?);
    }
    pub fn moveToNextProcess(self: *ExecutionContext) void {
        const currBatch = self.getCurrentBatch();
        (currBatch.getCurrent() catch unreachable).operation.calculate();

        currBatch.moveToNext() catch unreachable;
        if (currBatch.isDone()) {
            self.current_batch += 1;
        }
    }
    pub fn isComplete(self: *ExecutionContext) bool {
        return self.current_batch == self.batches.len;
    }

    pub fn isUniqueId(self: *ExecutionContext, id: []const u8) bool {
        for (0..self.current_process_idx) |i| {
            const p = self.getProcessWithGlobalIdx(usize_to(u16, i)) catch unreachable;
            if (std.mem.eql(u8, p.id, id)) return false;
        }

        return true;
    }
};

fn divideWithRemainder(comptime T: type, a: T, b: T) struct { T, T } {
    var div: T = 0;
    var rem = a;

    while (rem >= b) {
        rem -= b;
        div += 1;
    }
    return .{ div, rem };
}
