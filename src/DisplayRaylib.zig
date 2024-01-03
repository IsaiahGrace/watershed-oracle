const raylib = @cImport(@cInclude("raylib.h"));
const std = @import("std");
const watershed = @import("watershed.zig");

pub const Display = @This();

const screenWidth = 400;
const screenHeight = 240;

const State = enum {
    splash,
    watersheds,
};

satilites: u16,
state: State,
textBuffer: std.ArrayList(u8),
watershedStack: *const watershed.WatershedStack,

pub fn init(allocator: std.mem.Allocator, watershedStack: *const watershed.WatershedStack) Display {
    raylib.InitWindow(screenWidth, screenHeight, "Beepy LCD display");
    return Display{
        .textBuffer = std.ArrayList(u8).init(allocator),
        .state = .splash,
        .satilites = 0,
        .watershedStack = watershedStack,
    };
}

pub fn deinit(self: *Display) void {
    raylib.CloseWindow();
    self.textBuffer.deinit();
}

pub fn setSatilitesInView(self: *Display, totalNumSat: u16) !void {
    self.satilites = totalNumSat;
    try self.draw();
}

pub fn drawSplash(self: *Display) !void {
    self.state = .splash;
    try self.draw();
}

pub fn drawWatershedStack(self: *Display) !void {
    self.state = .watersheds;
    try self.draw();
}

pub fn draw(self: *Display) !void {
    raylib.BeginDrawing();
    raylib.ClearBackground(raylib.RAYWHITE);

    switch (self.state) {
        .splash => self.drawSplashScreen(),
        .watersheds => try self.drawWatersheds(),
    }

    try self.drawSatilitesInView();
    raylib.EndDrawing();
    raylib.SwapScreenBuffer();
}

fn drawSplashScreen(self: *const Display) void {
    _ = self;
    raylib.DrawText("Watershed Oracle", 20, 100, 40, raylib.BLACK);
}

fn drawSatilitesInView(self: *Display) !void {
    self.textBuffer.clearRetainingCapacity();
    try self.textBuffer.writer().print("{:2}\x00", .{self.satilites});
    raylib.DrawText(self.textBuffer.items.ptr, 350, 10, 25, raylib.BLACK);
}

fn drawWatershed(self: *Display, wshed: *const watershed.Watershed, posY: c_int) !void {
    self.textBuffer.clearRetainingCapacity();
    try self.textBuffer.writer().print("{s}\x00", .{&wshed.huc});
    raylib.DrawText(self.textBuffer.items.ptr, 10, posY, 10, raylib.BLACK);
    self.textBuffer.clearRetainingCapacity();
    try self.textBuffer.writer().print("{s}\x00", .{wshed.name});
    raylib.DrawText(self.textBuffer.items.ptr, 20, posY + 10, 20, raylib.BLACK);
}

fn drawWatersheds(self: *Display) !void {
    raylib.DrawText("Your watershed stack:", 20, 10, 25, raylib.BLACK);
    raylib.DrawLine(18, 35, screenWidth - 18, 35, raylib.BLACK);

    const DispData = struct {
        w: *const ?watershed.Watershed,
        posY: c_int,
    };
    const dispArray = [_]DispData{
        .{ .w = &self.watershedStack.huc2, .posY = 40 },
        .{ .w = &self.watershedStack.huc4, .posY = 70 },
        .{ .w = &self.watershedStack.huc6, .posY = 100 },
        .{ .w = &self.watershedStack.huc8, .posY = 130 },
        .{ .w = &self.watershedStack.huc10, .posY = 160 },
        .{ .w = &self.watershedStack.huc12, .posY = 190 },
    };

    for (dispArray) |d| {
        if (d.w.*) |*w| {
            try self.drawWatershed(w, d.posY);
        }
    }
}
