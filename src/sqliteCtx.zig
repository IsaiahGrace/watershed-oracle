const sqlite = @cImport(@cInclude("sqlite3.h"));
const sqliteErrors = @import("sqliteErrors.zig");
const std = @import("std");

// This struct is a helper abstraction on the SQLite3 DB for the USGS Watershed Boundary Dataset (WBD)
// The dataset is available for download here: https://prd-tnm.s3.amazonaws.com/index.html?prefix=StagedProducts/Hydrography/WBD/National/GPKG/
pub const SqliteCtx = struct {
    conn: ?*sqlite.sqlite3, // opaque pointer to SQLite3 database object

    pub fn init(path: [*:0]const u8) !SqliteCtx {
        var connectionPointer: ?*sqlite.sqlite3 = null;
        try sqliteErrors.check(sqlite.sqlite3_open_v2(@ptrCast(path), &connectionPointer, sqlite.SQLITE_OPEN_READWRITE, null));
        if (connectionPointer == null) return error.sqliteOOM;

        // These indicies will help with looking up the HUC codes
        try sqliteErrors.check(sqlite.sqlite3_exec(
            connectionPointer,
            \\CREATE INDEX IF NOT EXISTS huc_index2 ON WBDHU2 (huc2, name);
            \\CREATE INDEX IF NOT EXISTS huc_index4 ON WBDHU4 (huc4, name);
            \\CREATE INDEX IF NOT EXISTS huc_index6 ON WBDHU6 (huc6, name);
            \\CREATE INDEX IF NOT EXISTS huc_index8 ON WBDHU8 (huc8, name);
            \\CREATE INDEX IF NOT EXISTS huc_index10 ON WBDHU10 (huc10, name);
            \\CREATE INDEX IF NOT EXISTS huc_index12 ON WBDHU12 (huc12, name);
            \\CREATE INDEX IF NOT EXISTS huc_index14 ON WBDHU14 (huc14, name);
            \\CREATE INDEX IF NOT EXISTS huc_index16 ON WBDHU16 (huc16, name);
        ,
            null,
            null,
            null,
        ));

        return SqliteCtx{
            .conn = connectionPointer,
        };
    }

    pub fn deinit(self: *SqliteCtx) void {
        sqliteErrors.log(sqlite.sqlite3_close(self.conn));
        self.conn = null;
    }
};

test "Test DB Open and close" {
    var sctx = try SqliteCtx.init("/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg");
    defer sctx.deinit();
}

test "Select the name of HUC 22" {
    var sctx = try SqliteCtx.init("/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg");
    defer sctx.deinit();

    var statement: ?*sqlite.sqlite3_stmt = null;
    const query = "SELECT name FROM \"WBDHU2\" WHERE \"huc2\" IS '22';";
    try sqliteErrors.check(sqlite.sqlite3_prepare_v2(sctx.conn, query, query.len, &statement, null));
    defer sqliteErrors.log(sqlite.sqlite3_finalize(statement));

    try std.testing.expectEqual(sqlite.SQLITE_ROW, sqlite.sqlite3_step(statement));
    try std.testing.expectEqualSentinel(u8, 0, "South Pacific Region", std.mem.span(sqlite.sqlite3_column_text(statement, 0)));
    try std.testing.expectEqual(sqlite.SQLITE_DONE, sqlite.sqlite3_step(statement));
}
