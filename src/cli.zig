const sqlite = @cImport(@cInclude("sqlite3.h"));

const std = @import("std");
const watershed = @import("watershed.zig");

pub fn main() !void {
    if (std.os.argv.len < 2) {
        std.log.err("Provide full path to WBD_National_GPKG.gpkg", .{});
        std.log.err("NOTE: sqlite3 does not support ~/", .{});
        std.log.err("Try:", .{});
        std.log.err("zig build run -- /home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg", .{});
        return error.NoArgs;
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.log.err("GPA detected a leak!", .{});
    const allocator: std.mem.Allocator = gpa.allocator();

    var watershedStack = try watershed.WatershedStack.init(allocator, std.os.argv[1]);
    defer watershedStack.deinit();

    // In PA, near Hagerstown
    try watershedStack.updateWKT("POINT(-77.9510 39.7624)");
    try watershedStack.logPoint();
    try watershedStack.logStack();

    // In the national zoo, DC
    try watershedStack.updateXY(-77.047819, 38.927751);
    try watershedStack.logPoint();
    try watershedStack.logStack();

    // My apartment building
    try watershedStack.updateXY(-77.0369476121013, 38.93417495243022);
    try watershedStack.logPoint();
    try watershedStack.logStack();

    // Ocean Park, ME
    try watershedStack.updateXY(-70.38678136034306, 43.501440458688094);
    try watershedStack.logPoint();
    try watershedStack.logStack();
}
