const locationInterface = @import("interface.zig");
const std = @import("std");

pub const PointSrc = @This();

pub fn init(allocator: std.mem.Allocator, options: locationInterface.PointSrcOptions) PointSrc {
    _ = options;
    _ = allocator;
    return PointSrc{};
}

pub fn deinit(self: *PointSrc) void {
    _ = self;
}

pub fn nextPoint(self: *PointSrc) !locationInterface.Point {
    _ = self;
    return .{ .location = .{ .xy = .{ .x = 0, .y = 0 } } };
}
