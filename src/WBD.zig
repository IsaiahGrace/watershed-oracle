const std = @import("std");
const sqlite = @cImport(@cInclude("sqlite3.h"));
const sqliteErrors = @import("sqliteErrors.zig");

// This struct is a helper abstraction on the SQLite3 DB for the USGS Watershed Boundary Dataset (WBD)
// The dataset is available for download here: https://prd-tnm.s3.amazonaws.com/index.html?prefix=StagedProducts/Hydrography/WBD/National/GPKG/
pub const GeoPackage = struct {
    connection: *sqlite.sqlite3, // opaque pointer to SQLite3 database object

    pub fn init(path: [*:0]const u8) !GeoPackage {
        std.log.info("sqlite version: {s}", .{sqlite.SQLITE_VERSION});

        var connectionPointer: ?*sqlite.sqlite3 = null;
        try sqliteErrors.check(sqlite.sqlite3_open_v2(@ptrCast(path), &connectionPointer, sqlite.SQLITE_OPEN_READONLY, null));
        if (connectionPointer == null) return error.sqliteOOM;

        return GeoPackage{
            .connection = connectionPointer.?,
        };
    }

    pub fn deinit(self: *const GeoPackage) void {
        sqliteErrors.check(sqlite.sqlite3_close(self.connection)) catch |err| {
            std.log.err("Could not close sqlite3 connection: {s}", .{@errorName(err)});
        };
    }
};
