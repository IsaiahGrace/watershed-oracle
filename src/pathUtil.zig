const builtin = @import("builtin");
const clap = @import("clap");
const config = @import("config");
const PointFuzzer = @import("point/fuzzer.zig");
const PointGps = if (builtin.target.cpu.arch == .arm) @import("point/gps.zig") else @import("point/gpsMock.zig");
const PointScatter = @import("point/scatter.zig");
const PointStdin = @import("point/stdin.zig");
const std = @import("std");

const PointSources = union(config.@"build.PointProviders") {
    fuzzer: PointFuzzer,
    gps: PointGps,
    gpsMock: PointGps,
    scatter: PointScatter,
    stdin: PointStdin,
};

const params = clap.parseParamsComptime(
    \\-h, --help              Display this help and exit.
    \\-g, --gps               Collect point data from the GPS.
    \\-f, --fuzzer            Collect point data from the fuzzer.
    \\-s, --stdin             Collect point data from stdin.
    \\-c, --scatter           Randomly create point data.
    \\-n, --numPoints <usize> Collect only numPoints points.
);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.log.err("GPA detected a leak!", .{});
    const allocator: std.mem.Allocator = gpa.allocator();

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .allocator = allocator,
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    const stderr = std.io.getStdErr().writer();

    if (res.args.help != 0) {
        try clap.help(stderr, clap.Help, &params, .{});
        return;
    }

    var pointSrc: PointSources = pst: {
        if (res.args.gps != 0) {
            break :pst .{ .gps = PointGps.init(allocator, .{}) };
        }
        if (res.args.fuzzer != 0) {
            break :pst .{ .fuzzer = PointFuzzer.init(allocator, .{}) };
        }
        if (res.args.stdin != 0) {
            break :pst .{ .stdin = PointStdin.init(allocator, .{}) };
        }
        if (res.args.scatter != 0) {
            break :pst .{ .scatter = PointScatter.init(allocator, .{}) };
        }
        try clap.help(stderr, clap.Help, &params, .{});
        return;
    };
    defer switch (pointSrc) {
        inline else => |*src| src.deinit(),
    };

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const numPoints: usize = res.args.numPoints orelse std.math.maxInt(usize);
    var n: usize = 0;
    while (n <= numPoints) : (n += 1) {
        const point = switch (pointSrc) {
            inline else => |*src| src.nextPoint(),
        } catch |e| {
            switch (e) {
                error.NoMorePoints => break,
                else => return e,
            }
        };

        switch (point.location) {
            .wkt => |wkt| try stdout.print("{s}\n", .{wkt}),
            .xy => |xy| try stdout.print("POINT ({d} {d})\n", .{ xy.x, xy.y }),
        }
    }
    try bw.flush();
}
