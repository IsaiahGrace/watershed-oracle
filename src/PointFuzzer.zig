const std = @import("std");
const locationInterface = @import("pointInterface.zig");

pub const PointSrc = @This();

// huc: 05 - Ohio Region
// Envelope:
// minx: -89.2663719739644
// maxx: -77.83937040107634
// miny: 35.31331634622836
// maxy: 42.4498337184844

// huc: 06 - Tennessee Region
// Envelope:
// minx: -88.67959985925017
// maxx: -81.26111840201514
// miny: 34.11155983559371
// maxy: 37.24054551094525

// Combined envelope
// I'm picking these as the bounds for the fuzzer, because I think
// any point inside it should still be inside the dataset.
const minx: f64 = -89.2663719739644;
const maxx: f64 = -77.83937040107634;
const miny: f64 = 34.11155983559371;
const maxy: f64 = 42.4498337184844;

rng: std.rand.DefaultPrng,
x: f64,
y: f64,

pub fn init(allocator: std.mem.Allocator) PointSrc {
    _ = allocator;
    var rng = std.rand.DefaultPrng.init(1234);
    return PointSrc{
        .rng = rng,
        .x = rng.random().float(f64) * (maxx - minx) + minx,
        .y = rng.random().float(f64) * (maxy - miny) + miny,
    };
}

pub fn deinit(self: *PointSrc) void {
    _ = self;
}

pub fn nextPoint(self: *PointSrc) !locationInterface.Point {
    self.x += self.rng.random().floatNorm(f64) * 0.005;
    self.y += self.rng.random().floatNorm(f64) * 0.005;
    return .{ .xy = .{ .x = self.x, .y = self.y } };
}
