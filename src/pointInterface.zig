const config = @import("config");
const PointFuzzer = @import("PointFuzzer.zig").PointSrc;
const PointGPS = @import("PointGPS.zig").PointSrc;
const PointStdin = @import("PointStdin.zig").PointSrc;

pub const PointTypes = enum {
    wkt,
    xy,
};

pub const PointXY = struct {
    x: f64,
    y: f64,
};

pub const Point = union(PointTypes) {
    wkt: [*:0]u8,
    xy: PointXY,
};

pub const PointSrc = switch (config.pointProvider) {
    .stdin => PointStdin,
    .fuzzer => PointFuzzer,
    .gps => PointGPS,
};
