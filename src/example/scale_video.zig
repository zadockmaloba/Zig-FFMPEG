const std = @import("std");

const stdio = @cImport({
    @cInclude("stdio.h");
});

const libav = @cImport({
    @cInclude("libavutil/imgutils.h");
    @cInclude("libavutil/parseutils.h");
    @cInclude("libswscale/swscale.h");
});

fn fill_yuv_image(
    data: [*c][*c]u8,
    linesize: [*c]c_int,
    width: c_int,
    height: c_int,
    frame_index: c_int,
) void {
    var x: c_int = 0;
    var y: c_int = 0;

    while (y < height) : (y += 1) while (x < width) : (x += 1) {
        data[0][@intCast(y * linesize[0] + x)] = @intCast(x + y + frame_index * 3);
    };

    y = 0;
    x = 0;
    while (y < height) : (y += 1) while (x < width) : (x += 1) {
        data[1][@intCast(y * linesize[1] + x)] = @intCast(128 + y + frame_index * 2);
        data[2][@intCast(y * linesize[2] + x)] = @intCast(64 + x + frame_index * 5);
    };
}

pub inline fn exec(argc: u8, argv: []const [*c]const u8) void {
    const src_data: [*c][*c]u8 = null;
    const dst_data: [*c][*c]u8 = null;
    const src_linesize: [*c]c_int = null;
    const dst_linesize: [*c]c_int = null;
    const src_w: c_int = 320;
    const src_h: c_int = 240;
    var dst_w: c_int = undefined;
    var dst_h: c_int = undefined;

    const src_pix_fmt: libav.AVPixelFormat = libav.AV_PIX_FMT_YUV420P;
    const dst_pix_fmt: libav.AVPixelFormat = libav.AV_PIX_FMT_RGB24;

    var dst_size: [*c]const u8 = null;
    var dst_filename: [*c]const u8 = null;
    var dst_file: [*c]stdio.struct__IO_FILE = null; //TODO: Research on *std.c.FILE does not work

    var dst_bufsize: c_ulong = 0;
    var sws_ctx: ?*libav.SwsContext = null;

    var i: c_int = 0;
    var ret: c_int = 0;

    if (argc != 3) {
        //TODO: Use Zig standard library
        _ = stdio.fprintf(
            stdio.stderr,
            \\Usage: output_file output_size
            \\API example program to show how to scale an image with libswscale.
            \\This program generates a series of pictures, rescales them to the given
            \\output_size and saves them to an output file named output_file.
            \\
            ,
        );
        std.c.exit(1);
    }

    dst_filename = argv[1];
    dst_size = argv[2];

    if (libav.av_parse_video_size(&dst_w, &dst_h, dst_size) < 0) {
        //TODO: Use Zig standard library
        _ = stdio.fprintf(
            stdio.stderr,
            "Invalid size '%s', must be in the form WxH or a valid size abbreviation\n",
            dst_size,
        );
        std.c.exit(1);
    }

    //TODO: Use Zig standard library
    //NOTE: There is a significant difference when using functions imported from c.zig (std.c.____)
    //stdio.fopen and std.c.fopen return different types
    dst_file = stdio.fopen(dst_filename, "wb");

    if (dst_file == null) {
        _ = stdio.fprintf(
            stdio.stderr,
            "Could not open destination file %s\n",
            dst_filename,
        );
        std.c.exit(1);
    }

    // create scaling context
    sws_ctx = libav.sws_getContext(
        src_w,
        src_h,
        src_pix_fmt,
        dst_w,
        dst_h,
        dst_pix_fmt,
        libav.SWS_BILINEAR,
        null,
        null,
        null,
    );

    if (sws_ctx == null) {
        _ = stdio.fprintf(
            stdio.stderr,
            \\Impossible to create scale context for the conversion
            \\fmt:%s s:%dx%d -> fmt:%s s:%dx%d\n
        ,
            libav.av_get_pix_fmt_name(src_pix_fmt),
            src_w,
            src_h,
            libav.av_get_pix_fmt_name(dst_pix_fmt),
            dst_w,
            dst_h,
        );
        ret = libav.AVERROR(libav.EINVAL);
        fail(dst_file, src_data, dst_data, sws_ctx);
        //TODO: Return errors
        return;
    }

    // allocate source and destination image buffers
    ret = libav.av_image_alloc(
        src_data,
        src_linesize,
        src_w,
        src_h,
        src_pix_fmt,
        16,
    );

    if (ret < 0) {
        _ = stdio.fprintf(stdio.stderr, "Could not allocate source image\n");
        fail(dst_file, src_data, dst_data, sws_ctx);
        //TODO: Return errors
        return;
    }

    // allocate source and destination image buffers
    ret = libav.av_image_alloc(
        src_data,
        src_linesize,
        src_w,
        src_h,
        src_pix_fmt,
        16,
    );
    if (ret < 0) {
        _ = stdio.fprintf(stdio.stderr, "Could not allocate source image\n");
        fail(dst_file, src_data, dst_data, sws_ctx);
        //TODO: Return errors
        return;
    }

    //buffer is going to be written to rawvideo file, no alignment
    ret = libav.av_image_alloc(
        dst_data,
        dst_linesize,
        dst_w,
        dst_h,
        dst_pix_fmt,
        1,
    );
    if (ret < 0) {
        _ = stdio.fprintf(stdio.stderr, "Could not allocate destination image\n");
        fail(dst_file, src_data, dst_data, sws_ctx);
        //TODO: Return errors
        return;
    }
    dst_bufsize = @intCast(ret);

    while (i < 100) : (i += 1) {
        // generate synthetic video
        fill_yuv_image(
            src_data,
            src_linesize,
            src_w,
            src_h,
            i,
        );

        // convert to destination format
        _ = libav.sws_scale(
            sws_ctx,
            @as([*c]const [*c]const u8, src_data),
            src_linesize,
            0,
            src_h,
            dst_data,
            dst_linesize,
        );

        // write scaled image to file
        _ = stdio.fwrite(
            dst_data[0],
            1,
            dst_bufsize,
            dst_file,
        );
    }

    _ = stdio.fprintf(
        stdio.stderr,
        \\Scaling succeeded. Play the output file with the command:\n
        \\ffplay -f rawvideo -pix_fmt %s -video_size %dx%d %s\n
    ,
        libav.av_get_pix_fmt_name(dst_pix_fmt),
        dst_w,
        dst_h,
        dst_filename,
    );
}

fn fail(
    out_file: [*c]stdio.struct__IO_FILE,
    source_data: [*c][*c]u8,
    dest_data: [*c][*c]u8,
    context: ?*libav.SwsContext,
) void {
    //TODO: Handle possible errors
    _ = stdio.fclose(out_file);
    _ = source_data;
    _ = dest_data;
    //libav.av_freep(&source_data[0]);
    //libav.av_freep(&dest_data[0]);
    libav.sws_freeContext(context);
}
