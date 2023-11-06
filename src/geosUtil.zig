const geos_c = @cImport(@cInclude("geos_c.h"));
const std = @import("std");
const stdio = @cImport(@cInclude("stdio.h"));

const GeosCtx = struct {
    context: geos_c.GEOSContextHandle_t,

    // The init and deinit functions should only be called once at application startup
    pub fn init() GeosCtx {
        const newContext = geos_c.GEOS_init_r();

        geos_c.GEOSContext_setNoticeMessageHandler_r(newContext, geosNoticeMessageHandler, null);
        geos_c.GEOSContext_setErrorMessageHandler_r(newContext, geosErrorMessageHandler, null);

        return GeosCtx{
            .context = newContext,
        };
    }

    pub fn deinit(self: *GeosCtx) void {
        geos_c.GEOS_finish_r(self.context);
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

// These three magnificent functions took me several hours to write and pushed the limits of my understanding of the C language... but alas, there was a much easier API to use...

const GeosMsg = enum {
    info,
    err,
};

fn geosMsgHandler(msgType: GeosMsg, fmt: [*c]const u8, vaList: *std.builtin.VaList) void {
    // We'll use vsnprintf to tell us the message size, and then allocate a buffer large enough to hold the entire message
    var vaListCopy = @cVaCopy(vaList);
    const formattedLength: usize = @intCast(stdio.vsnprintf(null, @as(c_ulong, 0), fmt, @ptrCast(&vaListCopy)));

    // The GEOS library already uses C malloc, so in this callback we're going to abandon Zig doctrine to prevent having to manage a global static allocator.
    const msgBuffer = std.heap.raw_c_allocator.alloc(u8, formattedLength + 1) catch {
        std.log.err("Allocation of {d} bytes for GEOS message failed. Cannot print Message", .{formattedLength + 1});
        return;
    };
    defer std.heap.raw_c_allocator.free(msgBuffer);

    const bytesWritten: usize = @intCast(stdio.vsnprintf(@ptrCast(msgBuffer), msgBuffer.len, fmt, @ptrCast(vaList)));
    const msgSlice = msgBuffer[0..bytesWritten];
    switch (msgType) {
        .info => std.log.info("GEOS notice: {s}", .{msgSlice}),
        .err => std.log.err("GEOS error: {s}", .{msgSlice}),
    }
}

fn noticeMsgHandler(fmt: [*c]const u8, ...) callconv(.C) void {
    var vaList = @cVaStart();
    defer @cVaEnd(&vaList);
    geosMsgHandler(.info, fmt, &vaList);
}

fn errorMsgHandler(fmt: [*c]const u8, ...) callconv(.C) void {
    var vaList = @cVaStart();
    defer @cVaEnd(&vaList);
    geosMsgHandler(.err, fmt, &vaList);
}
