const std = @import("std");
const avio_list_dir = @import("example/avio_list_dir.zig");

pub fn main() !u8 {
    _ = avio_list_dir.exec();

    return 0;
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
