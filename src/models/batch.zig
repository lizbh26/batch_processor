const std = @import("std");
const Process = @import("process.zig").Process;

pub const BATCH_SIZE = 5;

pub const Batch = struct {
    queue: [BATCH_SIZE]?Process,

    pub fn init(extern_alloc: std.mem.Allocator) !*Batch {
        const self = try extern_alloc.create(Batch);
        return self;
    }
    pub fn deinit(self: *Batch, extern_alloc: std.mem.Allocator) void {
        extern_alloc.destroy(self);
    }
};
pub const ConstBatch = *const [BATCH_SIZE]*const Process;
