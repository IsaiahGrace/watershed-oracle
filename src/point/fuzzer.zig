const locationInterface = @import("interface.zig");
const std = @import("std");

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

dx: f64,
dy: f64,

pub fn init(allocator: std.mem.Allocator, options: locationInterface.PointSrcOptions) PointSrc {
    _ = options;
    _ = allocator;
    var rng = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
    return PointSrc{
        .rng = rng,
        .x = rng.random().float(f64) * (maxx - minx) + minx,
        .y = rng.random().float(f64) * (maxy - miny) + miny,
        .dx = 0,
        .dy = 0,
    };
}

pub fn deinit(self: *PointSrc) void {
    _ = self;
}

pub fn nextPoint(self: *PointSrc) !locationInterface.Point {
    // The "+ 0.1" gives a slight bias for the point to drift in the NE direction.
    // Hopefully this will help us travel to new places!
    self.dx += (self.rng.random().floatNorm(f64) + 0.1) * 0.0001;
    self.dy += (self.rng.random().floatNorm(f64) + 0.1) * 0.0001;
    self.x += self.dx;
    self.y += self.dy;
    return .{ .location = .{ .xy = .{ .x = self.x, .y = self.y } } };
}
