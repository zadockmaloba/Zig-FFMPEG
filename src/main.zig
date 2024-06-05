const std = @import("std");
const avio_list_dir = @import("example/avio_list_dir.zig");
const scale_video = @import("example/scale_video.zig");

pub fn main() !u8 {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    //AVIO list directory contents2
    _ = avio_list_dir.exec();

    return 0;
}

test "AVIO List Directories" {
    @import("std").testing.refAllDecls(@This());
    _ = avio_list_dir.exec();
}

test "Scale Video" {
    scale_video.exec(3, &[_][*c]const u8{
        "test",
        "/path/to/video",
        32,
    });
}
