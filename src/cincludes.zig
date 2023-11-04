const std = @import("std");
const stdio = @cImport(@cInclude("stdio.h"));
const stdarg = @cImport(@cInclude("stdarg.h"));
pub const geos = @cImport(@cInclude("geos_c.h"));
pub const sqlite = @cImport(@cInclude("sqlite3.h"));

// static void
// geos_msg_handler(const char* fmt, ...)
// {
//     va_list ap;
//     va_start(ap, fmt);
//     vprintf (fmt, ap);
//     va_end(ap);
// }

fn geos_notice_handler(fmt: [*c]const u8, ...) callconv(.C) void {
    var ap = @cVaStart();
    defer @cVaEnd(&ap);

    var msg = std.mem.zeroes([128]u8);
    _ = stdio.vsnprintf(@ptrCast(&msg), msg.len, fmt, @ptrCast(&ap));

    std.log.err("GEOS notice: {s}", .{msg});
}

fn geos_error_handler(fmt: [*c]const u8, ...) callconv(.C) void {
    var ap = @cVaStart();
    defer @cVaEnd(&ap);

    var msg = std.mem.zeroes([128]u8);
    _ = stdio.vsnprintf(@ptrCast(&msg), msg.len, fmt, @ptrCast(&ap));

    std.log.err("GEOS error: {s}", .{msg});
}

pub fn initGeos() !void {
    geos.initGEOS(geos_notice_handler, geos_error_handler);

    const reader = geos.GEOSWKTReader_create().?;
    defer geos.GEOSWKTReader_destroy(reader);

    const geom_a = geos.GEOSWKTReader_read(reader, "POIN(1 1)") orelse return;
    defer geos.GEOSGeom_destroy(geom_a);

    const writer = geos.GEOSWKTWriter_create().?;
    defer geos.GEOSWKTWriter_destroy(writer);

    const wkt = geos.GEOSWKTWriter_write(writer, geom_a).?;
    defer geos.GEOSFree(wkt);

    std.log.info("WKT: {s}", .{wkt});
}

pub fn deinitGeos() void {
    geos.finishGEOS();
}
