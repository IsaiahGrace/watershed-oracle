const geos_c = @cImport(@cInclude("geos_c.h"));
const GeosCtx = @import("geosCtx.zig").GeosCtx;
const gpkg = @import("gpkg.zig");
const sqlite = @cImport(@cInclude("sqlite3.h"));
const SqliteCtx = @import("sqliteCtx.zig").SqliteCtx;
const sqliteErrors = @import("sqliteErrors.zig");
const std = @import("std");

const Watershed = struct {
    huc: [16]u8,
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
        if (self.huc2) |huc| {
            self.allocator.free(huc.name);
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
        }
        if (self.huc4) |huc| {
            self.allocator.free(huc.name);
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
        }
        if (self.huc6) |huc| {
            self.allocator.free(huc.name);
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
        }
        if (self.huc8) |huc| {
            self.allocator.free(huc.name);
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
        }
        if (self.huc10) |huc| {
            self.allocator.free(huc.name);
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
        }
        if (self.huc12) |huc| {
            self.allocator.free(huc.name);
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
        }
        if (self.huc14) |huc| {
            self.allocator.free(huc.name);
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
        }
        if (self.huc16) |huc| {
            self.allocator.free(huc.name);
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
        }
        self.huc2 = null;
        self.huc4 = null;
        self.huc6 = null;
        self.huc8 = null;
        self.huc10 = null;
        self.huc12 = null;
        self.huc14 = null;
        self.huc16 = null;
        self.gctx.deinit();
        self.sctx.deinit();
    }

    pub fn logPoint(self: *const WatershedStack) !void {
        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.bufferedWriter(stdout_file);
        const stdout = bw.writer();

        if (self.point) |point| {
            var writer = geos_c.GEOSWKTWriter_create_r(self.gctx.handle);
            defer geos_c.GEOSWKTWriter_destroy_r(self.gctx.handle, writer);

            const pointWKT = geos_c.GEOSWKTWriter_write_r(self.gctx.handle, writer, point);
            defer geos_c.GEOSFree(pointWKT);

            try stdout.print("Point of interest: {s}\n", .{pointWKT});
        } else {
            try stdout.print("Point of interest not set.\n", .{});
        }
        try bw.flush();
    }

    pub fn logStack(self: *const WatershedStack) !void {
        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.bufferedWriter(stdout_file);
        const stdout = bw.writer();

        try stdout.print("Watershed stack:\n", .{});
        if (self.huc2) |watershed| try stdout.print("{s} : {s}\n", .{ watershed.huc, watershed.name });
        if (self.huc4) |watershed| try stdout.print("{s} : {s}\n", .{ watershed.huc, watershed.name });
        if (self.huc6) |watershed| try stdout.print("{s} : {s}\n", .{ watershed.huc, watershed.name });
        if (self.huc8) |watershed| try stdout.print("{s} : {s}\n", .{ watershed.huc, watershed.name });
        if (self.huc10) |watershed| try stdout.print("{s} : {s}\n", .{ watershed.huc, watershed.name });
        if (self.huc12) |watershed| try stdout.print("{s} : {s}\n", .{ watershed.huc, watershed.name });
        if (self.huc14) |watershed| try stdout.print("{s} : {s}\n", .{ watershed.huc, watershed.name });
        if (self.huc16) |watershed| try stdout.print("{s} : {s}\n", .{ watershed.huc, watershed.name });
        try bw.flush();
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
            if (geos_c.GEOSCovers_r(self.gctx.handle, huc.geom, self.point) == 1) return self.updateHUC4();
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc2 = null;
        return self.updateHUC2();
    }

    fn checkHUC4(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc4) |huc| {
            if (geos_c.GEOSCovers_r(self.gctx.handle, huc.geom, self.point) == 1) return self.updateHUC6();
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc4 = null;
        return self.checkHUC2();
    }

    fn checkHUC6(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc6) |huc| {
            if (geos_c.GEOSCovers_r(self.gctx.handle, huc.geom, self.point) == 1) return self.updateHUC8();
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc6 = null;
        return self.checkHUC4();
    }

    fn checkHUC8(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc8) |huc| {
            if (geos_c.GEOSCovers_r(self.gctx.handle, huc.geom, self.point) == 1) return self.updateHUC10();
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc8 = null;
        return self.checkHUC6();
    }

    fn checkHUC10(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc10) |huc| {
            if (geos_c.GEOSCovers_r(self.gctx.handle, huc.geom, self.point) == 1) return self.updateHUC12();
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc10 = null;
        return self.checkHUC8();
    }

    fn checkHUC12(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc12) |huc| {
            if (geos_c.GEOSCovers_r(self.gctx.handle, huc.geom, self.point) == 1) return self.updateHUC14();
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc12 = null;
        return self.checkHUC10();
    }

    fn checkHUC14(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc14) |huc| {
            if (geos_c.GEOSCovers_r(self.gctx.handle, huc.geom, self.point) == 1) return self.updateHUC16();
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc14 = null;
        return self.checkHUC12();
    }

    fn checkHUC16(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc16) |huc| {
            if (geos_c.GEOSCovers_r(self.gctx.handle, huc.geom, self.point) == 1) return;
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, huc.geom);
            self.allocator.free(huc.name);
        }
        self.huc16 = null;
        return self.checkHUC14();
    }

    // Updates propagate down the stack to smaller regions
    fn updateHUC2(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        self.huc2 = try self.search("huc2", "WBDHU2", "");
        return self.updateHUC4();
    }

    fn updateHUC4(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc2) |huc2| {
            self.huc4 = try self.search("huc4", "WBDHU4", huc2.huc[0..2]);
            return self.updateHUC6();
        }
    }

    fn updateHUC6(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc4) |huc4| {
            self.huc6 = try self.search("huc6", "WBDHU6", huc4.huc[0..4]);
            return self.updateHUC8();
        }
    }

    fn updateHUC8(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc6) |huc6| {
            self.huc8 = try self.search("huc8", "WBDHU8", huc6.huc[0..6]);
            return self.updateHUC10();
        }
    }

    fn updateHUC10(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc8) |huc8| {
            self.huc10 = try self.search("huc10", "WBDHU10", huc8.huc[0..8]);
            return self.updateHUC12();
        }
    }

    fn updateHUC12(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc10) |huc10| {
            self.huc12 = try self.search("huc12", "WBDHU12", huc10.huc[0..10]);
            return self.updateHUC14();
        }
    }

    fn updateHUC14(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc12) |huc12| {
            self.huc14 = self.search("huc14", "WBDHU14", huc12.huc[0..12]) catch |err| {
                switch (err) {
                    error.pointNotInDataset => return,
                    else => return err,
                }
            };
            return self.updateHUC16();
        }
    }

    fn updateHUC16(self: *WatershedStack) !void {
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc14) |huc14| {
            self.huc16 = try self.search("huc16", "WBDHU16", huc14.huc[0..14]);
        }
    }

    fn search(self: *WatershedStack, hucLevel: []const u8, tableName: []const u8, likePattern: []const u8) !Watershed {
        const queryString = try std.fmt.allocPrintZ(self.allocator, "SELECT {s},name,shape FROM \"{s}\" WHERE \"{s}\" LIKE '{s}%';", .{ hucLevel, tableName, hucLevel, likePattern });
        defer self.allocator.free(queryString);

        var statement: ?*sqlite.sqlite3_stmt = null;
        try sqliteErrors.check(sqlite.sqlite3_prepare_v2(self.sctx.conn, queryString, @intCast(queryString.len), &statement, null));
        defer sqliteErrors.log(sqlite.sqlite3_finalize(statement));

        var newGeom: ?*geos_c.GEOSGeometry = null;

        var reader = geos_c.GEOSWKBReader_create_r(self.gctx.handle);
        defer geos_c.GEOSWKBReader_destroy_r(self.gctx.handle, reader);

        // We'll use these to compare against the bounding boxes
        var pminX: f64 = undefined;
        var pmaxX: f64 = undefined;
        var pminY: f64 = undefined;
        var pmaxY: f64 = undefined;
        // GEOS will return zero if there was an exception getting the min/max.
        if (geos_c.GEOSGeom_getXMin_r(self.gctx.handle, self.point, &pminX) == 0) pminX = std.math.floatMax(f64);
        if (geos_c.GEOSGeom_getXMax_r(self.gctx.handle, self.point, &pmaxX) == 0) pmaxX = std.math.floatMin(f64);
        if (geos_c.GEOSGeom_getYMin_r(self.gctx.handle, self.point, &pminY) == 0) pminY = std.math.floatMax(f64);
        if (geos_c.GEOSGeom_getYMax_r(self.gctx.handle, self.point, &pmaxY) == 0) pmaxY = std.math.floatMin(f64);

        while (true) {
            const stepResult = try sqliteErrors.stepCheck(sqlite.sqlite3_step(statement));
            if (stepResult == sqlite.SQLITE_DONE) return error.pointNotInDataset;

            // Get the geometry data and do a check against the point.
            const shapeBlob: [*]const u8 = @ptrCast(sqlite.sqlite3_column_blob(statement, 2).?);
            const shapeSize: usize = @intCast(sqlite.sqlite3_column_bytes(statement, 2));

            std.log.debug("huc: {s} - {s}", .{ std.mem.span(sqlite.sqlite3_column_text(statement, 0)), std.mem.span(sqlite.sqlite3_column_text(statement, 1)) });

            const header: *const gpkg.Header = @alignCast(@ptrCast(shapeBlob));
            const envelopeSize = gpkg.envelopeSize(header);
            if (envelopeSize != 0) {
                const envelope: *const gpkg.EnvelopeXY = @alignCast(@ptrCast(shapeBlob + gpkg.headerSize));
                if (envelope.minx > pmaxX) continue;
                if (envelope.maxx < pminX) continue;
                if (envelope.miny > pmaxY) continue;
                if (envelope.maxy < pminY) continue;
            }

            var shape = geos_c.GEOSWKBReader_read_r(self.gctx.handle, reader, shapeBlob + gpkg.headerSize + envelopeSize, shapeSize);
            if (shape == null) return error.ReaderParseError;

            // if it does cover us, break!
            if (geos_c.GEOSCovers_r(self.gctx.handle, shape, self.point) == 1) {
                newGeom = shape;
                std.log.debug("Compared Geometry - Point within watershed!", .{});
                break;
            } else {
                std.log.debug("Compared Geometry - Point outside watershed.", .{});
                geos_c.GEOSGeom_destroy(shape);
            }
        }

        // Once we've found the point assign the huc and name.
        var newHuc = [16]u8{ ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ' };
        const hucSpan = std.mem.span(sqlite.sqlite3_column_text(statement, 0));
        @memcpy(newHuc[0..hucSpan.len], hucSpan);

        const nameSpan = std.mem.span(sqlite.sqlite3_column_text(statement, 1));
        var newName = try self.allocator.alloc(u8, nameSpan.len);
        errdefer self.allocator.free(newName);
        @memcpy(newName, nameSpan);

        var newWatershed = Watershed{
            .huc = newHuc,
            .name = newName,
            .geom = newGeom.?,
        };

        return newWatershed;
    }
};
