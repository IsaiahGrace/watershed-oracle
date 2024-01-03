const std = @import("std");
const watershed = @import("watershed.zig");

// This dummy display is imported by DisplayInterface.zig if config.gui is false
// The Display struct below allows us to use the same code in watershed.zig for both Gui and Core binaries.

pub const Display = @This();

pub fn init(allocator: std.mem.Allocator, watershedStack: *const watershed.WatershedStack) Display {
    _ = watershedStack;
    _ = allocator;
    return .{};
}

pub fn deinit(self: *Display) void {
    _ = self;
}

pub fn setSatilitesInView(self: *Display, totalNumSat: u16) !void {
    _ = totalNumSat;
    _ = self;
}

pub fn drawSplash(self: *Display) !void {
    _ = self;
}

pub fn drawWatershedStack(self: *Display) !void {
    _ = self;
}

pub fn draw(self: *Display) !void {
    _ = self;
}
