const std = @import("std");
const libav = @cImport({
    @cInclude("libavcodec/avcodec.h");
    @cInclude("libavformat/avformat.h");
    @cInclude("libavformat/avio.h");
});

const inttypes = @cImport({
    @cInclude("stdint.h");
    @cInclude("inttypes.h");
});

fn type_string(_type: c_int) [*c]const u8 {
    switch (_type) {
        libav.AVIO_ENTRY_DIRECTORY => return "<DIR>",
        libav.AVIO_ENTRY_FILE => return "<FILE>",
        libav.AVIO_ENTRY_BLOCK_DEVICE => return "<BLOCK DEVICE>",
        libav.AVIO_ENTRY_CHARACTER_DEVICE => return "<CHARACTER DEVICE>",
        libav.AVIO_ENTRY_NAMED_PIPE => return "<PIPE>",
        libav.AVIO_ENTRY_SYMBOLIC_LINK => return "<LINK>",
        libav.AVIO_ENTRY_SOCKET => return "<SOCKET>",
        libav.AVIO_ENTRY_SERVER => return "<SERVER>",
        libav.AVIO_ENTRY_SHARE => return "<SHARE>",
        libav.AVIO_ENTRY_WORKGROUP => return "<WORKGROUP>",
        else => {
            return "<UNKNOWN>";
        },
    }
}

fn list_op(input_dir: [*c]const u8) u32 {
    var entry: [*c]libav.AVIODirEntry = null;
    var ctx: [*c]libav.AVIODirContext = null;
    var cnt: c_int = 0;
    var ret: c_int = 0;
    //var filemode: ?[4]u8 = null;
    //var uid_and_gid: ?[20]u8 = null;
    std.debug.print("Openning Dir: {s} \n", .{input_dir});
    ret = libav.avio_open_dir(&ctx, input_dir, null);

    std.debug.print("Openning Dir: {s} Result: {} \nContext: {} \n", .{ input_dir, ret, ctx.* });

    if (ret < 0) {
        const args = [0]u8{};
        libav.av_log(null, libav.AV_LOG_ERROR, "Cannot list directory: %s.\n", &args);
        fail(&ctx);
        return 0;
    }

    cnt = 0;

    while (true) {
        ret = libav.avio_read_dir(ctx, &entry);
        //std.debug.print("*********************************\n", .{});
        //std.debug.print("Read Dir Result: {} \nContext: {} \nEntry: {*}\n", .{ ret, ctx.*, entry });

        if (ret < 0) {
            const args = [0]u8{};
            libav.av_log(null, libav.AV_LOG_ERROR, "Cannot list directory: %s.\n", &args);
            fail(&ctx);
            return 0;
        }

        if (entry == null) {
            std.debug.print("Entry is null \n", .{});
            fail(&ctx);
            break;
        }

        if (entry.*.filemode == -1)
            std.debug.print("???? {}\n", .{entry.*.filemode});

        if (cnt == 0)
            std.debug.print("{s} {s:>12} {s:>30} {s:>10} {s} {s:>16} {s:>16} {s:>16}\n", .{
                "TYPE",
                "SIZE",
                "NAME",
                "UID(GID)",
                "UGO",
                "MODIFIED",
                "ACCESSED",
                "STATUS_CHANGED",
            });

        std.debug.print("{s} {:>12} {s:>30} {:>10} {} {:>16} {:>16} {:>16}\n", .{
            type_string(entry.*.type),
            entry.*.size,
            entry.*.name,
            entry.*.user_id,
            entry.*.filemode,
            entry.*.modification_timestamp,
            entry.*.access_timestamp,
            entry.*.status_change_timestamp,
        });
        libav.avio_free_directory_entry(&entry);
        cnt += 1;
    }

    return 0;
}

fn fail(context: [*c][*c]libav.AVIODirContext) void {
    _ = libav.avio_close_dir(context);
}

pub fn exec() u32 {
    std.debug.print("Running avio_list_dir\n", .{});
    libav.av_log_set_level(libav.AV_LOG_DEBUG);
    _ = libav.avformat_network_init();
    defer _ = libav.avformat_network_deinit();

    //print out files in current working directory
    const res = list_op("./");

    return res;
}
