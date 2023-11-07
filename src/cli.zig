const sqlite = @cImport(@cInclude("sqlite3.h"));

const std = @import("std");
const watershed = @import("watershed.zig");

pub fn main() !void {
    std.log.info("Start CLI", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.log.err("GPA detected a leak!", .{});
    const allocator: std.mem.Allocator = gpa.allocator();

    var watershedStack = try watershed.WatershedStack.init(allocator, "/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg");
    defer watershedStack.deinit();

    try watershedStack.updateWKT("POINT(-77.9510 39.7624)");
    watershedStack.logPoint();
    watershedStack.logStack();

    // try watershedStack.updateXY(-77.047819, 38.927751);
    // watershedStack.logPoint();
    // watershedStack.logStack();
}
