const std = @import("std");
const cincludes = @import("cincludes.zig");
const geos = cincludes.geos;
const sqlite = cincludes.sqlite;

pub fn main() !void {
    std.log.info("sqlite version: {s}", .{sqlite.SQLITE_VERSION});
    std.log.info("geos version: {s}", .{geos.GEOS_VERSION});

    try cincludes.initGeos();
    defer cincludes.deinitGeos();
}
