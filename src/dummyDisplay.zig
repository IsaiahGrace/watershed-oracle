const std = @import("std");
const watershed = @import("watershed.zig");

// This dummy display is imported by watershed.zig if config.gui is false
// The Display struct below allows us to use the same code in watershed.zig for both Gui and Core binaries.

// This is kinda like a compile time vtable :)

pub const Display = @This();

pub fn init() Display {
    return Display{};
}

pub fn deinit(self: *Display) void {
    _ = self;
}

pub fn drawSplash(self: *const Display) void {
    _ = self;
}

fn drawWatershed(self: *Display, wshed: *watershed.Watershed, posY: c_int) !void {
    _ = posY;
    _ = wshed;
    _ = self;
}

fn drawCalculating(self: *Display, posY: c_int) void {
    _ = posY;
    _ = self;
}

pub fn drawWatershedStack(self: *Display, watershedStack: *watershed.WatershedStack) !void {
    _ = watershedStack;
    _ = self;
}
