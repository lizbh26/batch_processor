const Process = @import("process.zig");

pub const BATCH_SIZE = 5;

pub const Batch = *[BATCH_SIZE]*const Process.Process;
