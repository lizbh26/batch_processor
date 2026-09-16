const std = @import("std");

pub fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();

        arena: std.heap.ArenaAllocator,
        header: *UndirectedNode(T),

        pub fn init(extern_alloc: std.mem.Allocator) !Self {
            var arena = std.heap.ArenaAllocator.init(extern_alloc);

            const header = try arena.allocator().create(UndirectedNode(T));
            header.init(null);

            return Self{
                .arena = arena,
                .header = header,
            };
        }
        pub fn deinit(self: Self) void {
            self.arena.deinit();
        }

        pub fn isEmpty(self: Self) bool {
            return self.header.next == self.header;
        }
        pub fn length(self: Self) usize {
            var i: usize = 0;
            var curr = self.header.next;
            while (curr != self.header) {
                i += 1;
                curr = curr.next;
            }
            return i;
        }
        pub fn get(self: Self, i: usize) !*T {
            var curr = self.header;
            for (0..i + 1) |_| {
                curr = curr.next;
                if (curr == self.header) return error.OverFlow;
            }
            return curr.data.?;
        }

        pub fn enqueue(self: *Self, item: *T) !void {
            const new = try self.arena.allocator().create(UndirectedNode(T));
            new.init(item);

            self.header.prev.next = new;
            new.prev = self.header.prev;

            new.next = self.header;
            self.header.prev = new;
        }
        pub fn dequeue(self: *Self) !*T {
            if (self.isEmpty()) return error.UnderFlow;

            const p = self.header.next.data orelse return error.InvalidIndex;
            self.arena.allocator().destroy(self.header.next);

            self.header.next = self.header.next.next;
            self.header.next.prev = self.header;

            return p;
        }
        pub fn peek(self: Self) !*T {
            if (self.isEmpty()) return error.UnderFlow;
            return self.header.next.data.?;
        }
    };
}

fn UndirectedNode(comptime T: type) type {
    return struct {
        const Self = @This();

        prev: *Self,
        next: *Self,
        data: ?*T,

        pub fn init(self: *Self, data: ?*T) void {
            self.next = self;
            self.prev = self;
            self.data = data;
        }
    };
}
