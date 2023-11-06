const geos_c = @cImport(@cInclude("geos_c.h"));
const std = @import("std");

const GeosCtx = @import("geosCtx.zig").GeosCtx;
const SqliteCtx = @import("sqliteCtx.zig").SqliteCtx;

const HucLevel = enum {
    huc2,
    huc4,
    huc6,
    huc8,
    huc10,
    huc12,
    huc14,
    huc16,
};

const Huc = struct {
    code: [12]u8,
    level: HucLevel,
};

const Watershed = struct {
    huc: Huc,
    name: ?[*:0]const u8,
    geom: geos_c.GEOSGeom,
};

pub const WatershedStack = struct {
    allocator: std.mem.Allocator,
    sctx: SqliteCtx,
    gctx: GeosCtx,

    point: geos_c.GEOSGeom,

    huc2: ?Watershed,
    huc4: ?Watershed,
    huc6: ?Watershed,
    huc8: ?Watershed,
    huc10: ?Watershed,
    huc12: ?Watershed,
    huc14: ?Watershed,
    huc16: ?Watershed,

    pub fn init(allocator: std.mem.Allocator, gpkgPath: [*:0]const u8) !WatershedStack {
        const sqliteContext = try SqliteCtx.init(gpkgPath);
        errdefer sqliteContext.deinit();

        const geosContext = GeosCtx.init();
        errdefer geosContext.deinit();

        return WatershedStack{
            .allocator = allocator,
            .sctx = sqliteContext,
            .gctx = geosContext,
            .point = null,
            .huc2 = null,
            .huc4 = null,
            .huc6 = null,
            .huc8 = null,
            .huc10 = null,
            .huc12 = null,
            .huc14 = null,
            .huc16 = null,
        };
    }

    pub fn deinit(self: *WatershedStack) void {
        geos_c.GEOSGeom_destroy_r(self.gctx.handle, self.point);
        self.gctx.deinit();
        self.sctx.deinit();
    }
};
