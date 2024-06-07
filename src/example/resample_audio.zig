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

pub fn get_format_from_sample_fmt(fmt: []const [*c]const u8, sample_fmt: libav.AVSampleFormat) i32 {
    const sample_fmt_entries = [_]struct {
        const m_sample_fmt: libav.AVSampleFormat = undefined;
        const m_fmt_be: [*c]const u8 = undefined;
        const m_fmt_le: [*c]const u8 = undefined;
    }{
        .{
            .m_sample_fmt = libav.AV_SAMPLE_FMT_U8,
            .m_fmt_be = "u8",
            .m_fmt_le = "u8",
        },
        .{
            .m_sample_fmt = libav.AV_SAMPLE_FMT_S16,
            .m_fmt_be = "s16be",
            .m_fmt_le = "s16le",
        },
        .{
            .m_sample_fmt = libav.AV_SAMPLE_FMT_S32l,
            .m_fmt_be = "s32be",
            .m_fmt_le = "s32le",
        },
        .{
            .m_sample_fmt = libav.AV_SAMPLE_FMT_FLT,
            .m_fmt_be = "f32be",
            .m_fmt_le = "f32le",
        },
        .{
            .m_sample_fmt = libav.AV_SAMPLE_FMT_DBL,
            .m_fmt_be = "f64be",
            .m_fmt_le = "f64le",
        },
    };

    fmt.* = null;

    for (sample_fmt_entries, 0..) |_, indx| {
        const entry = &sample_fmt_entries[indx];
        if (sample_fmt == entry.*.sample_fmt) {
            fmt.ptr = libav.AV_NE(entry.*.m_fmt_be, entry.*.m_fmt_le);
            return 0;
        }
    }

    libav.fprintf(
        stdio.stderr,
        "Sample format %s not supported as output format\n",
        libav.av_get_sample_fmt_name(sample_fmt),
    );

    return libav.AVERROR(libav.EINVAL);
}

pub fn fill_samples(dst: [*c]f64, nb_samples: i32, nb_channels: i32, sample_rate: i32, t: [*c]f64) void {
    const tincr = 1.0 / sample_rate;
    var dstp = dst;

    const c: [*c]f64 = 2 * libav.M_PI * 440.0;

    //generate sin tone with 440Hz frequency and duplicated channels
    for (nb_samples, 0..) |_, i| {
        _ = i;
        dstp.* = std.math.sin(c * t.*);
        for (nb_channels, 0..) |_, j| {
            dstp[j] = dstp[0];
        }
        dstp += nb_channels;
        t.* += tincr;
    }
}

pub fn exec(argc: u8, argv: []const [*c]const u8) u8 {}
