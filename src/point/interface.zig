const config = @import("config");

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
    .stdin => @import("stdin.zig"),
    .fuzzer => @import("fuzzer.zig"),
    .gps => @import("gps.zig"),
    .scatter => @import("scatter.zig"),
};

pub const PointSrcOptions = struct {
    json: bool = false,
};
