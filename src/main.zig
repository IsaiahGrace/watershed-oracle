const std = @import("std");
const cincludes = @import("cincludes.zig");
const geos = @import("geos.zig");
const sqlite = cincludes.sqlite;

pub fn main() !void {
    std.log.info("sqlite version: {s}", .{sqlite.SQLITE_VERSION});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.log.err("GPA detected a leak!", .{});

    const allocator: std.mem.Allocator = gpa.allocator();

    geos.initGeos(allocator);
    defer geos.deinitGeos();
}
