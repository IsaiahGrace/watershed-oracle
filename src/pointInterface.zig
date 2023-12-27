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

pub const PointLocation = union(PointTypes) {
    wkt: [*:0]u8,
    xy: PointXY,
};

/// The `requestId` field is passed through and used by other programs to identify the point data
pub const Point = struct {
    requestId: u64 = 0,
    location: PointLocation,
};

pub const PointSrc = switch (config.pointProvider) {
    .stdin => PointStdin,
    .fuzzer => PointFuzzer,
    .gps => PointGPS,
};

pub const PointSrcOptions = struct {
    json: bool = false,
};
