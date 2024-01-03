const builtin = @import("builtin");
const Display = @import("../DisplayInterface.zig").Display;
const locationInterface = @import("interface.zig");
const nmea = @import("nmea.zig");
const pigpio = @cImport(@cInclude("pigpio.h"));
const pigpiod = @cImport(@cInclude("pigpiod_if2.h"));
const std = @import("std");

comptime {
    if (builtin.cpu.arch != .arm)
        @compileError("This file must be compiled for the Raspberry Pi.");
}

fn check(retval: c_int) SerialError!void {
    if (retval < 0) {
        std.log.err("pigpiod error: {d}", .{retval});
        return error.Pigpiod;
    }
}

fn tryCheck(retval: c_int) SerialError!u32 {
    try check(retval);
    return @intCast(retval);
}

const USER_BUTTON = 21;
const USER_LED = 20;
const ENABLE = 17; // Called DISABLE in docs. Powers the voltage regulator for the entire HAT
const GPS_FIX = 5;
const GEO_FENCE = 19;
const FORCE_ON = 13; // L96 pulling this high will force L96 out of backup mode. "$PMTK255,4*2F" will cause the L96 to go into backup mode until FOCE_ON goes high
const PPS_PIN = 6; // L96 one pulse per second

const L96_RESET = 26;
const L96_RX = 22;
const L96_TX = 27;
const L96_BAUD = 9600;

const SerialError = error{ Pigpiod, NoMorePoints };
const Reader = std.io.Reader(*PointSrc, SerialError, serialRead);

pub const PointSrc = @This();

allocator: std.mem.Allocator,
buffer: std.ArrayList(u8),
display: ?*Display,
handle: c_int,

pub fn init(allocator: std.mem.Allocator, options: locationInterface.PointSrcOptions) PointSrc {
    const handle = pigpiod.pigpio_start(null, null);
    if (handle < 0) @panic("pigpio_start() failed.");

    check(pigpiod.set_mode(handle, ENABLE, pigpio.PI_OUTPUT)) catch unreachable;
    check(pigpiod.set_mode(handle, FORCE_ON, pigpio.PI_OUTPUT)) catch unreachable;
    check(pigpiod.set_mode(handle, L96_RESET, pigpio.PI_OUTPUT)) catch unreachable;
    check(pigpiod.set_mode(handle, L96_TX, pigpio.PI_OUTPUT)) catch unreachable;
    check(pigpiod.set_mode(handle, USER_LED, pigpio.PI_OUTPUT)) catch unreachable;

    check(pigpiod.set_mode(handle, GEO_FENCE, pigpio.PI_INPUT)) catch unreachable;
    check(pigpiod.set_mode(handle, GPS_FIX, pigpio.PI_INPUT)) catch unreachable;
    check(pigpiod.set_mode(handle, L96_RX, pigpio.PI_INPUT)) catch unreachable;
    check(pigpiod.set_mode(handle, PPS_PIN, pigpio.PI_INPUT)) catch unreachable;
    check(pigpiod.set_mode(handle, USER_BUTTON, pigpio.PI_INPUT)) catch unreachable;

    check(pigpiod.gpio_write(handle, L96_RESET, 0)) catch unreachable;
    check(pigpiod.gpio_write(handle, FORCE_ON, 0)) catch unreachable;

    check(pigpiod.bb_serial_read_open(handle, L96_RX, L96_BAUD, 8)) catch unreachable;

    return PointSrc{
        .allocator = allocator,
        .buffer = std.ArrayList(u8).initCapacity(allocator, 128) catch unreachable,
        .display = options.display,
        .handle = handle,
    };
}

pub fn deinit(self: *PointSrc) void {
    check(pigpiod.bb_serial_read_close(self.handle, L96_RX)) catch unreachable;
    pigpiod.pigpio_stop(self.handle);
    self.buffer.deinit();
}

fn serialRead(self: *PointSrc, buffer: []u8) SerialError!usize {
    // The Reader interface specifies that returning zero indicates the
    // end of the stream. But our stream is never ending and the pigpiod
    // call often returns zero if there are no bytes currently available.
    while (true) {
        const bytesRead = try tryCheck(pigpiod.bb_serial_read(
            self.handle,
            L96_RX,
            @ptrCast(buffer.ptr),
            buffer.len,
        ));
        if (bytesRead > 0) return bytesRead;
        std.time.sleep(10 * std.time.ns_per_ms);
    }
}

pub fn nextPoint(self: *PointSrc) !locationInterface.Point {
    while (true) {
        self.buffer.clearRetainingCapacity();
        var reader = Reader{ .context = self };
        try reader.streamUntilDelimiter(self.buffer.writer(), '\n', null);
        const sentence = try nmea.parse(self.buffer.items);
        std.log.debug("{s}", .{self.buffer.items});
        // nmea.logSentence(sentence);

        if (self.display) |dsp| {
            switch (sentence) {
                .GSV => |gsv| try dsp.setSatilitesInView(gsv.totalNumSat),
                else => {},
            }
        }

        if (nmea.extractPoint(sentence)) |point| {
            return point;
        }
    }
}
