const config = @import("config");
const geos_c = @cImport({
    @cDefine("GEOS_USE_ONLY_R_API", {});
    @cInclude("geos_c.h");
});
const GeosCtx = @import("geosCtx.zig").GeosCtx;
const gpkg = @import("gpkg.zig");
const Point = @import("point/interface.zig").Point;
const sqlite = @cImport(@cInclude("sqlite3.h"));
const SqliteCtx = @import("sqliteCtx.zig").SqliteCtx;
const sqliteErrors = @import("sqliteErrors.zig");
const std = @import("std");

pub const Watershed = struct {
    huc: [16]u8,
    name: []const u8,
    geom: *geos_c.GEOSGeometry,
};

const Bounds = struct {
    minX: f64,
    maxX: f64,
    minY: f64,
    maxY: f64,
};

pub const WatershedStack = struct {
    allocator: std.mem.Allocator,
    sctx: SqliteCtx,
    gctx: GeosCtx,

    // HUC levels 14 and 16 are not defined for most of the country, and the SQL lookup for
    // these levels is almost always a waste of time. This switch just skips these two levels.
    skipHuc14and16: bool,

    point: geos_c.GEOSGeom = null,
    pointBounds: Bounds,
    requestId: i64 = 0,

    huc2: ?Watershed = null,
    huc4: ?Watershed = null,
    huc6: ?Watershed = null,
    huc8: ?Watershed = null,
    huc10: ?Watershed = null,
    huc12: ?Watershed = null,
    huc14: ?Watershed = null,
    huc16: ?Watershed = null,

    pub fn init(allocator: std.mem.Allocator, gpkgPath: []const u8, skipHuc14and16: bool) !WatershedStack {
        // We need to provide a null terminated path to SqliteCtx.init(), so we'll have to add that null byte here
        var pathBuffer = try std.ArrayList(u8).initCapacity(allocator, gpkgPath.len + 1);
        defer pathBuffer.deinit();
        try pathBuffer.appendSlice(gpkgPath);
        try pathBuffer.append(0);

        const sqliteContext = try SqliteCtx.init(@ptrCast(pathBuffer.items));
        errdefer sqliteContext.deinit();

        const geosContext = GeosCtx.init();
        errdefer geosContext.deinit();

        return WatershedStack{
            .allocator = allocator,
            .sctx = sqliteContext,
            .gctx = geosContext,
            .skipHuc14and16 = skipHuc14and16,
            .pointBounds = .{
                .minX = std.math.floatMax(f64),
                .maxX = std.math.floatMin(f64),
                .minY = std.math.floatMax(f64),
                .maxY = std.math.floatMin(f64),
            },
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

    pub fn valid(self: *const WatershedStack) bool {
        if (self.huc2 != null or
            self.huc4 != null or
            self.huc6 != null or
            self.huc8 != null or
            self.huc10 != null or
            self.huc12 != null or
            self.huc14 != null or
            self.huc16 != null)
        {
            return true;
        }
        return false;
    }

    pub fn printPoint(self: *const WatershedStack) !void {
        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.bufferedWriter(stdout_file);
        const stdout = bw.writer();

        if (self.point) |point| {
            const writer = geos_c.GEOSWKTWriter_create_r(self.gctx.handle);
            defer geos_c.GEOSWKTWriter_destroy_r(self.gctx.handle, writer);

            const pointWKT = geos_c.GEOSWKTWriter_write_r(self.gctx.handle, writer, point);
            defer geos_c.GEOSFree_r(self.gctx.handle, pointWKT);

            try stdout.print("Point of interest: {s}\n", .{pointWKT});
        } else {
            try stdout.print("Point of interest not set.\n", .{});
        }
        try bw.flush();
    }

    pub fn printStack(self: *const WatershedStack) !void {
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

    pub fn printJSON(self: *const WatershedStack) !void {
        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.bufferedWriter(stdout_file);
        const stdout = bw.writer();

        var ws = std.json.writeStream(stdout, .{ .whitespace = .minified });
        defer ws.deinit();
        try ws.beginObject();
        try ws.objectField("requestId");
        try ws.write(self.requestId);

        if (!self.valid()) {
            try ws.objectField("pointNotInDataset");
            try ws.write(true);
        }

        if (self.point) |point| {
            const writer = geos_c.GEOSWKTWriter_create_r(self.gctx.handle);
            defer geos_c.GEOSWKTWriter_destroy_r(self.gctx.handle, writer);
            const pointWKT = geos_c.GEOSWKTWriter_write_r(self.gctx.handle, writer, point);
            defer geos_c.GEOSFree_r(self.gctx.handle, pointWKT);
            try ws.objectField("point");
            try ws.beginObject();
            try ws.objectField("WKT");
            try ws.write(@as([*:0]u8, @ptrCast(pointWKT)));
            try ws.objectField("longitude");
            try ws.write(self.pointBounds.minX);
            try ws.objectField("latitude");
            try ws.write(self.pointBounds.minY);
            try ws.endObject();
        }

        if (self.huc2) |watershed| {
            try ws.objectField("huc2");
            try ws.beginObject();
            try ws.objectField("name");
            try ws.write(watershed.name);
            try ws.objectField("huc");
            try ws.write(watershed.huc[0..2]);
            try ws.endObject();
        }
        if (self.huc4) |watershed| {
            try ws.objectField("huc4");
            try ws.beginObject();
            try ws.objectField("name");
            try ws.write(watershed.name);
            try ws.objectField("huc");
            try ws.write(watershed.huc[0..4]);
            try ws.endObject();
        }
        if (self.huc6) |watershed| {
            try ws.objectField("huc6");
            try ws.beginObject();
            try ws.objectField("name");
            try ws.write(watershed.name);
            try ws.objectField("huc");
            try ws.write(watershed.huc[0..6]);
            try ws.endObject();
        }
        if (self.huc8) |watershed| {
            try ws.objectField("huc8");
            try ws.beginObject();
            try ws.objectField("name");
            try ws.write(watershed.name);
            try ws.objectField("huc");
            try ws.write(watershed.huc[0..8]);
            try ws.endObject();
        }
        if (self.huc10) |watershed| {
            try ws.objectField("huc10");
            try ws.beginObject();
            try ws.objectField("name");
            try ws.write(watershed.name);
            try ws.objectField("huc");
            try ws.write(watershed.huc[0..10]);
            try ws.endObject();
        }
        if (self.huc12) |watershed| {
            try ws.objectField("huc12");
            try ws.beginObject();
            try ws.objectField("name");
            try ws.write(watershed.name);
            try ws.objectField("huc");
            try ws.write(watershed.huc[0..12]);
            try ws.endObject();
        }
        if (self.huc14) |watershed| {
            try ws.objectField("huc14");
            try ws.beginObject();
            try ws.objectField("name");
            try ws.write(watershed.name);
            try ws.objectField("huc");
            try ws.write(watershed.huc[0..14]);
            try ws.endObject();
        }
        if (self.huc16) |watershed| {
            try ws.objectField("huc16");
            try ws.beginObject();
            try ws.objectField("name");
            try ws.write(watershed.name);
            try ws.objectField("huc");
            try ws.write(watershed.huc[0..16]);
            try ws.endObject();
        }
        try ws.endObject();
        try stdout.print("\n", .{});
        try bw.flush();
    }

    fn clearPoint(self: *WatershedStack) void {
        if (self.point) |point| {
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, point);
            self.point = null;
        }
        self.pointBounds = .{
            .minX = std.math.floatMax(f64),
            .maxX = std.math.floatMin(f64),
            .minY = std.math.floatMax(f64),
            .maxY = std.math.floatMin(f64),
        };
    }

    pub fn update(self: *WatershedStack, newPoint: Point) !void {
        self.requestId = newPoint.requestId;
        switch (newPoint.location) {
            .wkt => |wkt| try self.updateWKT(wkt),
            .xy => |xy| try self.updateXY(xy.x, xy.y),
        }
    }

    pub fn updateWKT(self: *WatershedStack, newPoint: [*:0]const u8) !void {
        self.clearPoint();

        const reader = geos_c.GEOSWKTReader_create_r(self.gctx.handle);
        defer geos_c.GEOSWKTReader_destroy_r(self.gctx.handle, reader);

        self.point = geos_c.GEOSWKTReader_read_r(self.gctx.handle, reader, newPoint);
        if (self.point == null) return error.updateWKT;
        try self.updateStack();
    }

    pub fn updateXY(self: *WatershedStack, x: f64, y: f64) !void {
        self.clearPoint();
        self.point = geos_c.GEOSGeom_createPointFromXY_r(self.gctx.handle, x, y);
        if (self.point == null) return error.updateXY;
        try self.updateStack();
    }

    fn updateStack(self: *WatershedStack) !void {
        // The point has been updated, now re-validate the watershed stack.
        if (self.point == null) return error.updateNullPoint;

        // We'll use these to compare against the bounding boxes
        // GEOS will return zero if there was an exception getting the min/max.
        if (geos_c.GEOSGeom_getXMin_r(self.gctx.handle, self.point, &self.pointBounds.minX) == 0)
            self.pointBounds.minX = std.math.floatMax(f64);
        if (geos_c.GEOSGeom_getXMax_r(self.gctx.handle, self.point, &self.pointBounds.maxX) == 0)
            self.pointBounds.maxX = std.math.floatMin(f64);
        if (geos_c.GEOSGeom_getYMin_r(self.gctx.handle, self.point, &self.pointBounds.minY) == 0)
            self.pointBounds.minY = std.math.floatMax(f64);
        if (geos_c.GEOSGeom_getYMax_r(self.gctx.handle, self.point, &self.pointBounds.maxY) == 0)
            self.pointBounds.maxY = std.math.floatMin(f64);

        const err = if (self.skipHuc14and16)
            self.checkHUC12()
        else
            self.checkHUC16();

        if (err) {} else |e| {
            switch (e) {
                error.pointNotInDataset => {
                    const writer = geos_c.GEOSWKTWriter_create_r(self.gctx.handle);
                    defer geos_c.GEOSWKTWriter_destroy_r(self.gctx.handle, writer);

                    const wkt = geos_c.GEOSWKTWriter_write_r(self.gctx.handle, writer, self.point);
                    defer geos_c.GEOSFree_r(self.gctx.handle, wkt);

                    std.log.err("Point given is outside the dataset: {s}", .{wkt});
                },
                else => {},
            }
        }
        return err;
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
        if (self.skipHuc14and16) return;
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
        if (self.skipHuc14and16) return;
        std.log.debug("{s}", .{@src().fn_name});
        if (self.huc14) |huc14| {
            self.huc16 = try self.search("huc16", "WBDHU16", huc14.huc[0..14]);
        }
    }

    fn searchStep(
        self: *WatershedStack,
        tableName: [*:0]const u8,
        statement: *sqlite.sqlite3_stmt,
        reader: *geos_c.GEOSWKBReader,
    ) !?*geos_c.GEOSGeometry {
        // Run an SQLite3 step on the statement, generating the next result from our query
        const stepResult = try sqliteErrors.stepCheck(sqlite.sqlite3_step(statement));
        if (stepResult == sqlite.SQLITE_DONE) return error.pointNotInDataset;

        std.log.debug("huc: {s} - {s}", .{
            std.mem.span(sqlite.sqlite3_column_text(statement, 1)),
            std.mem.span(sqlite.sqlite3_column_text(statement, 2)),
        });

        // Open the shape column of the result row in blob mode, so we can read just the header of
        // the geometry. The header contains the bounds of the shape, so we can compare our point to
        // these bounds as a cheaper check for coverage, instead of loading the entire polygon.
        const rowid = sqlite.sqlite3_column_int64(statement, 0);
        var blob: ?*sqlite.sqlite3_blob = null;
        try sqliteErrors.check(
            sqlite.sqlite3_blob_open(self.sctx.conn, "main", tableName, "shape", rowid, 0, &blob),
        );
        defer sqliteErrors.log(sqlite.sqlite3_blob_close(blob));

        var header: gpkg.HeaderAndEnvelopeXY = undefined;
        try sqliteErrors.check(sqlite.sqlite3_blob_read(blob, &header, @sizeOf(@TypeOf(header)), 0));

        // Compare the header envelope with our points bounds, to see if we even need to read the full point geometry
        if ((header.envelopeXY.minx > self.pointBounds.maxX) or
            (header.envelopeXY.maxx < self.pointBounds.minX) or
            (header.envelopeXY.miny > self.pointBounds.maxY) or
            (header.envelopeXY.maxy < self.pointBounds.minY))
        {
            return null;
        }

        const geometry = geom: {
            const blobSize: usize = @intCast(sqlite.sqlite3_blob_bytes(blob));
            const shapeBuffer: []u8 = try self.allocator.alloc(u8, blobSize - @sizeOf(@TypeOf(header)));
            defer self.allocator.free(shapeBuffer);
            try sqliteErrors.check(
                sqlite.sqlite3_blob_read(blob, shapeBuffer.ptr, @intCast(shapeBuffer.len), @sizeOf(@TypeOf(header))),
            );
            break :geom geos_c.GEOSWKBReader_read_r(self.gctx.handle, reader, shapeBuffer.ptr, shapeBuffer.len).?;
        };

        // Check if the new geometry covers our point of interest
        if (geos_c.GEOSCovers_r(self.gctx.handle, geometry, self.point) != 1) {
            std.log.debug("Compared Geometry - Point outside watershed.", .{});
            geos_c.GEOSGeom_destroy_r(self.gctx.handle, geometry);
            return null;
        }

        std.log.debug("Compared Geometry - Point within watershed!", .{});
        return geometry;
    }

    fn search(
        self: *WatershedStack,
        hucLevel: []const u8,
        tableName: [*:0]const u8,
        likePattern: []const u8,
    ) !Watershed {
        // Create the SQL query string
        const queryString = try std.fmt.allocPrintZ(
            self.allocator,
            "SELECT rowid,{s},name FROM \"{s}\" WHERE \"{s}\" LIKE '{s}%';",
            .{ hucLevel, tableName, hucLevel, likePattern },
        );
        defer self.allocator.free(queryString);

        // Prepare the SQLite3 statement from the query string
        const statement = stmt: {
            var optStatement: ?*sqlite.sqlite3_stmt = null;
            try sqliteErrors.check(
                sqlite.sqlite3_prepare_v2(
                    self.sctx.conn,
                    queryString,
                    @intCast(queryString.len),
                    &optStatement,
                    null,
                ),
            );
            break :stmt optStatement.?;
        };
        defer sqliteErrors.log(sqlite.sqlite3_finalize(statement));

        // Create a new geos WKB reader to parse the shape blobs we'll read from the DB
        const reader = geos_c.GEOSWKBReader_create_r(self.gctx.handle).?;
        defer geos_c.GEOSWKBReader_destroy_r(self.gctx.handle, reader);

        // Repeat searchStep() until we find a matching geometry, or an error is returned
        const newGeom = geom: {
            while (true) {
                if (try self.searchStep(tableName, statement, reader)) |g| break :geom g;
            }
        };

        // Once we've found the point assign the huc and name.
        var newHuc = [16]u8{ ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ' };
        const hucSpan = std.mem.span(sqlite.sqlite3_column_text(statement, 1));
        @memcpy(newHuc[0..hucSpan.len], hucSpan);

        const nameSpan = std.mem.span(sqlite.sqlite3_column_text(statement, 2));
        const newName = try self.allocator.alloc(u8, nameSpan.len);
        errdefer self.allocator.free(newName);
        @memcpy(newName, nameSpan);

        return Watershed{
            .huc = newHuc,
            .name = newName,
            .geom = newGeom,
        };
    }
};
