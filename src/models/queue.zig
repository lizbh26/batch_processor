const std = @import("std.zig");

pub fn SimpleQueue(comptime T: type) type {
    return struct {
        const Self = @This();

        alloc: std.mem.Allocator,

        items: []T,
        size: usize,

        front: usize,
        end: usize,

        fn getNextNumber(self: Self, n: usize) usize {
            if (n == self.size - 1) return 0 else return n + 1;
        }
        fn getPrevNumber(self: Self, n: usize) usize {
            return (if (n == 0) self.size else n) - 1;
        }

        pub fn init(alloc: std.mem.Allocator, size: usize) !Self {
            return Self{
                .alloc = alloc,
                .items = try alloc.alloc(T, size),
                .size = size,
                .front = 0,
                .end = size - 1,
            };
        }
        pub fn deinit(self: Self) void {
            self.alloc.free(self.items);
        }

        pub fn isEmpty(self: Self) bool {
            return self.front == self.end + 1 or (self.front == 0 and self.end == self.size - 1);
        }
        pub fn isFull(self: Self) bool {
            return self.front == self.end + 2 or (self.front == 0 and self.end == self.size - 2) or (self.front == 1 and self.end == self.size - 1);
        }
        pub fn length(self: Self) usize {
            if (self.isEmpty()) return 0;
            if (self.isFull()) return self.size;
            if (self.front < self.end) return self.end - self.front + 1;
            return (self.end + 1) + (self.size - self.front);
        }

        pub fn enqueue(self: *Self, item: T) !void {
            if (self.isFull()) return error.OverFlow;
            self.end = self.getNextNumber(self.end);
            self.items[self.end] = item;
        }
        pub fn dequeue(self: *Self) !T {
            if (self.isEmpty()) return error.UnderFlow;
            const prev = self.front;
            self.front = self.getNextNumber(prev);
            return self.items[prev];
        }
        pub fn peek(self: Self) !T {
            if (self.isEmpty()) return error.UnderFlow;
            return self.items[self.front];
        }
    };
}
