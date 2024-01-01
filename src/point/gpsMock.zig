const locationInterface = @import("interface.zig");
const std = @import("std");
const nmea = @import("nmea.zig");
const stdin = @import("stdin.zig");

pub const PointSrc = @This();

allocator: std.mem.Allocator,
stdin: std.fs.File,
stdinBuffer: std.ArrayList(u8),

pub fn init(allocator: std.mem.Allocator, options: locationInterface.PointSrcOptions) PointSrc {
    _ = options;
    return PointSrc{
        .allocator = allocator,
        .stdin = std.io.getStdIn(),
        .stdinBuffer = std.ArrayList(u8).init(allocator),
    };
}

pub fn deinit(self: *PointSrc) void {
    self.stdinBuffer.deinit();
}

fn readandParseLine(self: *PointSrc) !nmea.Sentence {
    self.stdinBuffer.clearRetainingCapacity();
    self.stdin.reader().streamUntilDelimiter(self.stdinBuffer.writer(), '\n', null) catch |e| {
        switch (e) {
            error.EndOfStream => return error.NoMorePoints,
            else => return e,
        }
    };
    return try nmea.parse(self.stdinBuffer.items);
}

pub fn nextPoint(self: *PointSrc) !locationInterface.Point {
    while (true) {
        const sentence = self.readandParseLine() catch |e| {
            switch (e) {
                error.invalidNMEA => return e,
                else => return e,
            }
        };
        nmea.logSentence(sentence);
        if (nmea.extractPoint(sentence)) |point| {
            return point;
        }
    }
}
