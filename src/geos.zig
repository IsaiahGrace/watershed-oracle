const geos_c = @cImport(@cInclude("geos_c.h"));
const std = @import("std");
const stdio = @cImport(@cInclude("stdio.h"));

const GeosMsg = enum {
    info,
    err,
};

// The allocator is needed in the message handler callback from GEOS
var msgCallbackAllocator: ?std.mem.Allocator = null;

fn geosMsgHandler(msgType: GeosMsg, fmt: [*c]const u8, vaList: *std.builtin.VaList) void {
    if (msgCallbackAllocator == null) {
        std.log.err("msgCallbackAllocator is null, cannot print GEOS message. Call initGeos() first.", .{});
        return;
    }

    // We'll use vsnprintf to tell us the message size, and then allocate a buffer large enough to hold the entire message
    var vaListCopy = @cVaCopy(vaList);
    const formattedLength: usize = @intCast(stdio.vsnprintf(null, @as(c_ulong, 0), fmt, @ptrCast(&vaListCopy)));

    const msgBuffer = msgCallbackAllocator.?.alloc(u8, formattedLength + 1) catch {
        std.log.err("Allocation of {d} bytes for GEOS message failed. Cannot print Message", .{formattedLength + 1});
        return;
    };
    defer msgCallbackAllocator.?.free(msgBuffer);

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

pub fn initGeos(allocator: std.mem.Allocator) void {
    std.log.debug("geos version: {s}", .{geos_c.GEOS_VERSION});
    msgCallbackAllocator = allocator;
    geos_c.initGEOS(noticeMsgHandler, errorMsgHandler);
}

pub fn deinitGeos() void {
    geos_c.finishGEOS();
}
