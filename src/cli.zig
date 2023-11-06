const std = @import("std");
const geosUtil = @import("geosUtil.zig");
const sqlite = @cImport(@cInclude("sqlite3.h"));
const wbd = @import("wbd.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.log.err("GPA detected a leak!", .{});

    const allocator: std.mem.Allocator = gpa.allocator();

    geosUtil.initGeos(allocator);
    defer geosUtil.deinitGeos();

    var dataset = try wbd.Wbd.init("/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg");
    defer dataset.deinit();
}
