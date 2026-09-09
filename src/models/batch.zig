const std = @import("std");
const Process = @import("process.zig").Process;

pub const BATCH_SIZE = 5;

pub const BatchError = error{AccessWhenDone};
pub const Batch = struct {
    queue: [BATCH_SIZE]?Process,
    current: u16,
    done: u16,
    size: u16,


    pub fn isDone(self: *Batch) bool {
        return self.done == self.size;
    }

    pub fn getCurrent(self: *Batch) !*Process {
        if (self.isDone()) return BatchError.AccessWhenDone;
        return &self.queue[self.current].?;
    }

    fn next(self: *Batch) !void {
        if (self.isDone()) return BatchError.AccessWhenDone;
        while ((try self.getCurrent()).isDone()) {
            self.current += 1;
            if (self.current == self.size) self.current = 0;
        }
    }
    pub fn moveToNext(self: *Batch) !void {
        if ((try self.getCurrent()).isDone()) self.done += 1;
        if (self.isDone()) return;
        try self.next();
    }
};
