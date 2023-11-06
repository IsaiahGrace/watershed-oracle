const geos_c = @cImport(@cInclude("geos_c.h"));
const std = @import("std");
const stdio = @cImport(@cInclude("stdio.h"));

pub const GeosCtx = struct {
    handle: geos_c.GEOSContextHandle_t,

    pub fn init() GeosCtx {
        const newHandle = geos_c.GEOS_init_r();
        _ = geos_c.GEOSContext_setNoticeMessageHandler_r(newHandle, geosNoticeMessageHandler, null);
        _ = geos_c.GEOSContext_setErrorMessageHandler_r(newHandle, geosErrorMessageHandler, null);
        return GeosCtx{
            .handle = newHandle,
        };
    }

    pub fn deinit(self: *GeosCtx) void {
        geos_c.GEOS_finish_r(self.handle);
        self.handle = null;
    }
};

fn geosNoticeMessageHandler(message: [*c]const u8, userdata: ?*anyopaque) callconv(.C) void {
    _ = userdata;
    std.log.info("GEOS notice: {s}", .{message});
}

fn geosErrorMessageHandler(message: [*c]const u8, userdata: ?*anyopaque) callconv(.C) void {
    _ = userdata;
    std.log.err("GEOS error: {s}", .{message});
}
