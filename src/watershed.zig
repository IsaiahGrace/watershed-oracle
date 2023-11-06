const geos_c = @cImport(@cInclude("geos_c.h"));
const std = @import("std");

const GeosCtx = @import("geosCtx.zig").GeosCtx;
const SqliteCtx = @import("sqliteCtx.zig").SqliteCtx;

const Watershed = struct {
    huc: [12]u8,
    name: []const u8,
    geom: *geos_c.GEOSGeometry,
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
        self.clearPoint();
        self.gctx.deinit();
        self.sctx.deinit();
    }

    pub fn logPoint(self: *const WatershedStack) void {
        if (self.point) |point| {
            var writer = geos_c.GEOSWKTWriter_create_r(self.gctx.handle);
            defer geos_c.GEOSWKTWriter_destroy_r(self.gctx.handle, writer);

            const pointWKT = geos_c.GEOSWKTWriter_write_r(self.gctx.handle, writer, point);
            defer geos_c.GEOSFree(pointWKT);

            std.log.info("Point of interest: {s}", .{pointWKT});
        } else {
            std.log.info("Point of interest not set.", .{});
        }
    }

    pub fn logStack(self: *const WatershedStack) void {
        std.log.info("Watershed stack:", .{});
        if (self.huc2) |watershed| std.log.info("{s} : {s}", .{ watershed.huc, watershed.name });
        if (self.huc4) |watershed| std.log.info("{s} : {s}", .{ watershed.huc, watershed.name });
        if (self.huc6) |watershed| std.log.info("{s} : {s}", .{ watershed.huc, watershed.name });
        if (self.huc8) |watershed| std.log.info("{s} : {s}", .{ watershed.huc, watershed.name });
        if (self.huc10) |watershed| std.log.info("{s} : {s}", .{ watershed.huc, watershed.name });
        if (self.huc12) |watershed| std.log.info("{s} : {s}", .{ watershed.huc, watershed.name });
        if (self.huc14) |watershed| std.log.info("{s} : {s}", .{ watershed.huc, watershed.name });
        if (self.huc16) |watershed| std.log.info("{s} : {s}", .{ watershed.huc, watershed.name });
    }

    fn clearPoint(self: *WatershedStack) void {
        if (self.point) |point| {
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, point);
            self.point = null;
        }
    }

    pub fn updateWKT(self: *WatershedStack, newPoint: [*:0]const u8) !void {
        self.clearPoint();

        var reader = geos_c.GEOSWKTReader_create_r(self.gctx.handle);
        defer geos_c.GEOSWKTReader_destroy_r(self.gctx.handle, reader);

        self.point = geos_c.GEOSWKTReader_read_r(self.gctx.handle, reader, newPoint);
        if (self.point == null) return error.updateWKT;
        try self.update();
    }

    pub fn updateXY(self: *WatershedStack, x: f64, y: f64) !void {
        self.clearPoint();
        self.point = geos_c.GEOSGeom_createPointFromXY_r(self.gctx.handle, x, y);
        if (self.point == null) return error.updateXY;
        try self.update();
    }

    fn update(self: *WatershedStack) !void {
        // The point has been updated, now re-validate the watershed stack.
        if (self.point == null) return error.updateNullPoint;
        try self.checkHUC16();
    }

    // All check and update functions assume that self.point is not null

    // Checks propagate up the stack to larger geographic regions
    fn checkHUC2(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc2) |huc| {
            if (geos_c.GEOSCovers_r(self.gctx.handle, self.point, huc.geom) == 1) return self.updateHUC4();
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc2 = null;
        return self.updateHUC2();
    }

    fn checkHUC4(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc4) |huc| {
            if (geos_c.GEOSCovers_r(self.gctx.handle, self.point, huc.geom) == 1) return self.updateHUC6();
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc4 = null;
        return self.checkHUC2();
    }

    fn checkHUC6(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc6) |huc| {
            if (geos_c.GEOSCovers_r(self.gctx.handle, self.point, huc.geom) == 1) return self.updateHUC8();
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc6 = null;
        return self.checkHUC4();
    }

    fn checkHUC8(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc8) |huc| {
            if (geos_c.GEOSCovers_r(self.gctx.handle, self.point, huc.geom) == 1) return self.updateHUC10();
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc8 = null;
        return self.checkHUC6();
    }

    fn checkHUC10(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc10) |huc| {
            if (geos_c.GEOSCovers_r(self.gctx.handle, self.point, huc.geom) == 1) return self.updateHUC12();
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc10 = null;
        return self.checkHUC8();
    }

    fn checkHUC12(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc12) |huc| {
            if (geos_c.GEOSCovers_r(self.gctx.handle, self.point, huc.geom) == 1) return self.updateHUC14();
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc12 = null;
        return self.checkHUC10();
    }

    fn checkHUC14(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc14) |huc| {
            if (geos_c.GEOSCovers_r(self.gctx.handle, self.point, huc.geom) == 1) return self.updateHUC16();
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc14 = null;
        return self.checkHUC12();
    }

    fn checkHUC16(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc16) |huc| {
            if (geos_c.GEOSCovers_r(self.gctx.handle, self.point, huc.geom) == 1) return;
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc16 = null;
        return self.checkHUC14();
    }

    // Updates propagate down the stack to smaller regions
    fn updateHUC2(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        // Maybe return error.pointNotInDataset??
        try self.updateHUC4();
    }

    fn updateHUC4(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        try self.updateHUC6();
    }

    fn updateHUC6(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        try self.updateHUC8();
    }

    fn updateHUC8(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        try self.updateHUC10();
    }

    fn updateHUC10(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        try self.updateHUC12();
    }

    fn updateHUC12(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        try self.updateHUC14();
    }

    fn updateHUC14(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        try self.updateHUC16();
    }

    fn updateHUC16(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        // HUC levels 14 and 16 are not always available, if updateHUC14 was unable to find a
        // watershed, don't bother looking for an HUC16 code, it won't exist.
        if (self.huc14 == null) return;
    }
};
