const locationInterface = @import("pointInterface.zig");
const std = @import("std");

pub const PointSrc = @This();

allocator: std.mem.Allocator,
stdin: std.fs.File,
stdinBuffer: std.ArrayList(u8),

pub fn init(allocator: std.mem.Allocator) PointSrc {
    return PointSrc{
        .allocator = allocator,
        .stdin = std.io.getStdIn(),
        .stdinBuffer = std.ArrayList(u8).init(allocator),
    };
}

pub fn deinit(self: *PointSrc) void {
    self.stdinBuffer.deinit();
}

pub fn nextPoint(self: *PointSrc) !locationInterface.Point {
    self.stdinBuffer.clearRetainingCapacity();
    self.stdin.reader().streamUntilDelimiter(self.stdinBuffer.writer(), '\n', null) catch |e| {
        switch (e) {
            error.EndOfStream => return error.NoMoreLocations,
            else => return e,
        }
    };
    try self.stdinBuffer.append(0);
    // The @ptrCast() is hacky, but I'm not sure what the "correct" thing to do here is..
    return locationInterface.Point{ .wkt = @ptrCast(self.stdinBuffer.items) };
}
