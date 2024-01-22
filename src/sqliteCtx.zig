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

        // These indices will help with looking up the HUC codes
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
