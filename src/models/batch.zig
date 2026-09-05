const std = @import("std");
const Process = @import("process.zig").Process;

pub const BATCH_SIZE = 5;

pub const Batch = struct {
    queue: [BATCH_SIZE]?Process,
};
pub const ConstBatch = *const [BATCH_SIZE]*const Process;
