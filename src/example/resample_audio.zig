const std = @import("std");

const libav = @cImport({
    @cInclude("libavutil/opt.h");
    @cInclude("libavutil/channel_layout.h");
    @cInclude("libavutil/samplefmt.h");
    @cInclude("libswresample/swresample.h");
});

const stdio = @cImport({
    @cInclude("stdio.h");
});

pub fn get_format_from_sample_fmt(fmt: []const [*c]const u8, sample_fmt: libav.AVSampleFormat) i32 {}

pub fn exec(argc: u8, argv: []const [*c]const u8) u8 {}
