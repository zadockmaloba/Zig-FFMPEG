const std = @import("std");
const avio_list_dir = @import("example/avio_list_dir.zig");
const scale_video = @import("example/scale_video.zig");

pub fn main() !u8 {

    //AVIO list directory contents2
    _ = avio_list_dir.exec();

    scale_video.exec(1, &[_][*]const u8{});
    return 0;
}

test "AVIO List Directories" {
    _ = avio_list_dir.exec();
}
