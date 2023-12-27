const locationInterface = @import("pointInterface.zig");
const std = @import("std");

pub const PointSrc = @This();

allocator: std.mem.Allocator,
options: locationInterface.PointSrcOptions,
stdin: std.fs.File,
stdinBuffer: std.ArrayList(u8),

pub fn init(allocator: std.mem.Allocator, options: locationInterface.PointSrcOptions) PointSrc {
    return PointSrc{
        .allocator = allocator,
        .options = options,
        .stdin = std.io.getStdIn(),
        .stdinBuffer = std.ArrayList(u8).init(allocator),
    };
}

pub fn deinit(self: *PointSrc) void {
    self.stdinBuffer.deinit();
}

const PointJson = struct {
    requestId: u64 = 0,
    longitude: f64,
    latitude: f64,
};

pub fn nextPoint(self: *PointSrc) !locationInterface.Point {
    self.stdinBuffer.clearRetainingCapacity();
    self.stdin.reader().streamUntilDelimiter(self.stdinBuffer.writer(), '\n', null) catch |e| {
        switch (e) {
            error.EndOfStream => return error.NoMorePoints,
            else => return e,
        }
    };

    if (self.options.json) {
        const parsedPoint = try std.json.parseFromSlice(PointJson, self.allocator, self.stdinBuffer.items, .{});
        defer parsedPoint.deinit();
        return locationInterface.Point{
            .requestId = parsedPoint.value.requestId,
            .location = .{
                .xy = .{
                    .x = parsedPoint.value.longitude,
                    .y = parsedPoint.value.latitude,
                },
            },
        };
    } else {
        try self.stdinBuffer.append(0);
        // The @ptrCast() is hacky, but I'm not sure what the "correct" thing to do here is..
        return locationInterface.Point{
            .location = .{
                .wkt = @ptrCast(self.stdinBuffer.items),
            },
        };
    }
}
