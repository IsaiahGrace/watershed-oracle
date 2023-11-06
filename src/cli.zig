const sqlite = @cImport(@cInclude("sqlite3.h"));

const std = @import("std");
const watershed = @import("watershed.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.log.err("GPA detected a leak!", .{});
    const allocator: std.mem.Allocator = gpa.allocator();

    var watershedStack = try watershed.WatershedStack.init(allocator, "/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg");
    defer watershedStack.deinit();

    // watershedStack.updateWKT("PointData");
    // watershedStack.logStack();
}
