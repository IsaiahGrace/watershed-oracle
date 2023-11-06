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
        sqliteErrors.log(sqlite.sqlite3_close(self.connection));
    }
};

test "Test DB Open and close" {
    const wbd = try GeoPackage.init("/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg");
    defer wbd.deinit();
}

test "Select the name of HUC 22" {
    const wbd = try GeoPackage.init("/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg");
    defer wbd.deinit();

    var statement: ?*sqlite.sqlite3_stmt = null;
    const query = "SELECT name FROM \"WBDHU2\" WHERE \"huc2\" IS '22';";
    try sqliteErrors.check(sqlite.sqlite3_prepare_v2(wbd.connection, query, query.len, &statement, null));
    defer sqliteErrors.log(sqlite.sqlite3_finalize(statement));

    try std.testing.expectEqual(sqlite.SQLITE_ROW, sqlite.sqlite3_step(statement));
    try std.testing.expectEqualSentinel(u8, 0, "South Pacific Region", std.mem.span(sqlite.sqlite3_column_text(statement, 0)));
    try std.testing.expectEqual(sqlite.SQLITE_DONE, sqlite.sqlite3_step(statement));
}
