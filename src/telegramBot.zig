const std = @import("std");
const geosUtil = @import("geosUtil.zig");
const sqlite = @cImport(@cInclude("sqlite3.h"));

pub fn main() !void {
    std.log.info("sqlite version: {s}", .{sqlite.SQLITE_VERSION});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.log.err("GPA detected a leak!", .{});

    const allocator: std.mem.Allocator = gpa.allocator();

    geosUtil.initGeos(allocator);
    defer geosUtil.deinitGeos();
}
