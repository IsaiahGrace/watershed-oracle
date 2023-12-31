const locationInterface = @import("interface.zig");
const std = @import("std");

pub const PointSrc = @This();

// I made a rough rectangle around the continental US, and here is what I got:
// POLYGON ((
// -126 24,
// -126 50,
// -66 50,
// -66 24,
// -126 24
// ))

// Combined envelope
// I'm picking these as the bounds for the fuzzer, because I think
// any point inside it should still be inside the dataset.
const minx: f64 = -126.0;
const maxx: f64 = -66.0;
const miny: f64 = 24.0;
const maxy: f64 = 50.0;

rng: std.rand.DefaultPrng,

pub fn init(allocator: std.mem.Allocator, options: locationInterface.PointSrcOptions) PointSrc {
    _ = options;
    _ = allocator;
    var rng = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
    return PointSrc{
        .rng = rng,
    };
}

pub fn deinit(self: *PointSrc) void {
    _ = self;
}

pub fn nextPoint(self: *PointSrc) !locationInterface.Point {
    return .{
        .location = .{
            .xy = .{
                .x = self.rng.random().float(f64) * (maxx - minx) + minx,
                .y = self.rng.random().float(f64) * (maxy - miny) + miny,
            },
        },
    };
}
