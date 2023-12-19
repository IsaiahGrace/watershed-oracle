const clap = @import("clap");
const std = @import("std");
const config = @import("config");
const PointFuzzer = @import("PointFuzzer.zig");
//const PointGPS = @import("PointGPS.zig");
const PointStdin = @import("PointStdin.zig");

const PointSources = union(config.@"build.PointProviders") {
    stdin: PointStdin,
    fuzzer: PointFuzzer,
    gps: PointFuzzer,
};

const params = clap.parseParamsComptime(
    \\-h, --help              Display this help and exit.
    \\-g, --gps               Collect point data from the GPS.
    \\-f, --fuzzer            Collect point data from the fuzzer.
    \\-s, --stdin             Collect point data from stdin.
    \\-n, --numPoints <usize> Collect only numPoints points. 
);

pub fn main() !void {
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.log.err("GPA detected a leak!", .{});
    const allocator: std.mem.Allocator = gpa.allocator();

    const stderr = std.io.getStdErr().writer();

    if (res.args.help != 0) {
        try clap.help(stderr, clap.Help, &params, .{});
        return;
    }

    var pointSrc: PointSources = pst: {
        if (res.args.gps != 0) {
            break :pst .{ .gps = PointFuzzer.init(allocator) };
        }
        if (res.args.fuzzer != 0) {
            break :pst .{ .fuzzer = PointFuzzer.init(allocator) };
        }
        if (res.args.stdin != 0) {
            break :pst .{ .stdin = PointStdin.init(allocator) };
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

    const numPoints: usize = res.args.numPoints orelse std.math.maxInt(i64);
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

        switch (point) {
            .wkt => |wkt| try stdout.print("{s}\n", .{wkt}),
            .xy => |xy| try stdout.print("POINT ({d} {d})\n", .{ xy.x, xy.y }),
        }
    }
    try bw.flush();
}
