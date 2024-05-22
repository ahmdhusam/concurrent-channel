const std = @import("std");
const Mutex = std.Thread.Mutex;
const Condition = std.Thread.Condition;
const Allocator = std.mem.Allocator;

pub fn Channel(comptime T: type) type {
    return struct {
        mutex: Mutex,
        cond: Condition,
        queue: std.DoublyLinkedList(T),
        allocator: Allocator,

        pub const Chan = @This();

        pub const Tx = struct {
            chan: *Chan,

            pub fn send(self: *const Tx, element: T) !void {
                try self.chan.put(element);
            }
        };

        pub const Rx = struct {
            chan: *Chan,

            pub fn recv(self: *const Rx) T {
                return self.chan.take();
            }
        };

        pub fn init(allocator: Allocator) !*Chan {
            const chan = try allocator.create(Chan);

            chan.allocator = allocator;
            chan.mutex = .{};
            chan.cond = .{};
            chan.queue = .{};

            return chan;
        }

        pub fn deinit(self: *Chan) void {
            defer self.allocator.destroy(self);

            self.mutex.lock();
            defer self.mutex.unlock();

            while (self.queue.popFirst()) |node| {
                self.allocator.destroy(node);
            }
        }

        pub fn getTx(self: *Chan) Tx {
            return .{ .chan = self };
        }

        pub fn getRx(self: *Chan) Rx {
            return .{ .chan = self };
        }

        pub fn put(self: *Chan, data: T) !void {
            self.mutex.lock();
            defer {
                self.mutex.unlock();
                self.cond.signal();
            }

            const node = try self.allocator.create(std.DoublyLinkedList(T).Node);
            node.data = data;

            self.queue.append(node);
        }

        pub fn take(self: *Chan) T {
            self.mutex.lock();
            while (true) {
                const node = self.queue.popFirst() orelse {
                    self.cond.wait(&self.mutex);
                    continue;
                };

                self.mutex.unlock();
                defer self.allocator.destroy(node);

                return node.data;
            }
        }
    };
}
