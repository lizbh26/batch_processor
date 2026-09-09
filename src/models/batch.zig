const std = @import("std");
const Process = @import("process.zig").Process;

pub const BATCH_SIZE = 5;

pub const BatchError = error{AccessWhenDone};
pub const Batch = struct {
    queue: [BATCH_SIZE]?Process,
    current: u16,
    done: u16,
    size: u16,

    pub fn seed(self: *Batch, random: std.Random, size: u16, batchIdx: usize) void {
        self.size = @min(size, BATCH_SIZE);

        for (0..self.size) |i| {
            self.queue[i].?.seed(random, .{ .batchIdx = batchIdx, .id = batchIdx * BATCH_SIZE + i + 1 });
        }
        for (self.size..BATCH_SIZE) |i| {
            self.queue[i] = null;
        }
        self.done = 0;
        self.current = 0;
    }

    pub fn isDone(self: *Batch) bool {
        return self.done == self.size;
    }

    pub fn getCurrent(self: *Batch) !*Process {
        if (self.isDone()) return BatchError.AccessWhenDone;
        return &self.queue[self.current].?;
    }

    fn next(self: *Batch) !void {
        if (self.isDone()) return BatchError.AccessWhenDone;
        while (true) {
            self.current += 1;
            if (self.current == self.size) self.current = 0;
            if (!(try self.getCurrent()).isDone()) return;
        }
    }
    pub fn moveToNext(self: *Batch) !void {
        if ((try self.getCurrent()).isDone()) self.done += 1;
        if (self.isDone()) return;
        try self.next();
    }
};
