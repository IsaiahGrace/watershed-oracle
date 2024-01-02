const locationInterface = @import("interface.zig");
const std = @import("std");
const builtin = @import("builtin");
const pigpio = @cImport(@cInclude("pigpio.h"));
const pigpiod = @cImport(@cInclude("pigpiod_if2.h"));

comptime {
    if (builtin.cpu.arch != .arm)
        @compileError("This file must be compiled for the Raspberry Pi.");
}

fn check(retval: c_int) !void {
    if (retval < 0) {
        std.log.err("pigpio error: {d}", .{retval});
        return error.pigpio;
    }
}

fn tryCheck(retval: c_int) !u32 {
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

pub const PointSrc = @This();

allocator: std.mem.Allocator,
handle: c_int,
buffer: [128]u8,
index: usize,

pub fn init(allocator: std.mem.Allocator, options: locationInterface.PointSrcOptions) PointSrc {
    _ = options;

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
        .handle = handle,
        .buffer = undefined,
        .index = 0,
    };
}

pub fn deinit(self: *PointSrc) void {
    check(pigpiod.bb_serial_read_close(self.handle, L96_RX)) catch unreachable;
    pigpiod.pigpio_stop(self.handle);
}

pub fn nextPoint(self: *PointSrc) !locationInterface.Point {
    std.time.sleep(100 * std.time.ns_per_ms);
    const bytesRead = try tryCheck(pigpiod.bb_serial_read(
        self.handle,
        L96_RX,
        @ptrCast(&self.buffer[self.index]),
        self.buffer.len - self.index,
    ));
    std.log.info("bytesRead: {d} index: {d}", .{ bytesRead, self.index });
    std.log.info("buffer:\n{s}", .{self.buffer});
    self.index += bytesRead;
    if (self.index >= self.buffer.len) self.index = 0;
    return .{ .location = .{ .xy = .{ .x = 0, .y = 0 } } };
}
