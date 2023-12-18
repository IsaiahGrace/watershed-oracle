const raylib = @cImport(@cInclude("raylib.h"));
const std = @import("std");
const watershed = @import("watershed.zig");

pub const Display = @This();

const screenWidth = 400;
const screenHeight = 240;

textBuffer: std.ArrayList(u8),

pub fn init(allocator: std.mem.Allocator) Display {
    raylib.InitWindow(screenWidth, screenHeight, "Beepy LCD display");
    return Display{
        .textBuffer = std.ArrayList(u8).init(allocator),
    };
}

pub fn deinit(self: *Display) void {
    raylib.CloseWindow();
    self.textBuffer.deinit();
}

pub fn drawSplash(self: *const Display) void {
    _ = self;
    raylib.BeginDrawing();
    raylib.ClearBackground(raylib.RAYWHITE);
    raylib.DrawText("Watershed Oracle", 20, 100, 40, raylib.BLACK);
    raylib.EndDrawing();
    raylib.SwapScreenBuffer();
}

fn drawWatershed(self: *Display, wshed: *watershed.Watershed, posY: c_int) !void {
    self.textBuffer.clearRetainingCapacity();
    try self.textBuffer.appendSlice(&wshed.huc);
    try self.textBuffer.append(0);
    raylib.DrawText(self.textBuffer.items.ptr, 10, posY, 10, raylib.BLACK);
    self.textBuffer.clearRetainingCapacity();
    try self.textBuffer.appendSlice(wshed.name);
    try self.textBuffer.append(0);
    raylib.DrawText(self.textBuffer.items.ptr, 20, posY + 10, 20, raylib.BLACK);
}

fn drawCalculating(self: *Display, posY: c_int) void {
    _ = self;
    raylib.DrawText("calculating...", 20, posY + 10, 20, raylib.BLACK);
}

pub fn drawWatershedStack(self: *Display, watershedStack: *watershed.WatershedStack) !void {
    raylib.BeginDrawing();

    raylib.ClearBackground(raylib.RAYWHITE);

    raylib.DrawText("Your watershed stack:", 20, 10, 20, raylib.BLACK);
    raylib.DrawLine(18, 35, screenWidth - 18, 35, raylib.BLACK);

    const DispData = struct {
        w: *?watershed.Watershed,
        posY: c_int,
    };
    const dispArray = [_]DispData{
        .{ .w = &watershedStack.huc2, .posY = 40 },
        .{ .w = &watershedStack.huc4, .posY = 70 },
        .{ .w = &watershedStack.huc6, .posY = 100 },
        .{ .w = &watershedStack.huc8, .posY = 130 },
        .{ .w = &watershedStack.huc10, .posY = 160 },
        .{ .w = &watershedStack.huc12, .posY = 190 },
    };

    var printedCalculating = false;

    for (dispArray) |d| {
        if (d.w.*) |*w| {
            try self.drawWatershed(w, d.posY);
        } else if (!printedCalculating) {
            std.log.debug("Printing Calculating. posY = {d}", .{d.posY});
            self.drawCalculating(d.posY);
            printedCalculating = true;
        }
    }

    raylib.EndDrawing();
    raylib.SwapScreenBuffer();
}
