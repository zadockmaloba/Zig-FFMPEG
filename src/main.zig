const std = @import("std");
const avio_list_dir = @import("example/avio_list_dir.zig");

pub fn main() !u8 {

    //AVIO list directory contents2
    _ = avio_list_dir.exec();

    return 0;
}

test "AVIO List Directories" {
    _ = avio_list_dir.exec();
}
