const raylib = @cImport(@cInclude("raylib.h"));
const std = @import("std");
const watershed = @import("watershed.zig");

const screenWidth = 400;
const screenHeight = 240;

pub const Display = struct {
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

    fn drawWatershed(self: *Display, wshed: watershed.Watershed, posY: c_int) !void {
        self.textBuffer.clearRetainingCapacity();
        try self.textBuffer.appendSlice(&wshed.huc);
        try self.textBuffer.append(0);
        raylib.DrawText(self.textBuffer.items.ptr, 10, posY, 10, raylib.BLACK);
        self.textBuffer.clearRetainingCapacity();
        try self.textBuffer.appendSlice(wshed.name);
        try self.textBuffer.append(0);
        raylib.DrawText(self.textBuffer.items.ptr, 20, posY + 10, 20, raylib.BLACK);
    }

    pub fn drawWatershedStack(self: *Display, watershedStack: *watershed.WatershedStack) !void {
        raylib.BeginDrawing();

        raylib.ClearBackground(raylib.RAYWHITE);

        raylib.DrawText("Your watershed stack:", 20, 10, 20, raylib.BLACK);
        raylib.DrawLine(18, 35, screenWidth - 18, 35, raylib.BLACK);

        if (watershedStack.huc2) |w| try self.drawWatershed(w, 40);
        if (watershedStack.huc4) |w| try self.drawWatershed(w, 70);
        if (watershedStack.huc6) |w| try self.drawWatershed(w, 100);
        if (watershedStack.huc8) |w| try self.drawWatershed(w, 130);
        if (watershedStack.huc10) |w| try self.drawWatershed(w, 160);
        if (watershedStack.huc12) |w| try self.drawWatershed(w, 190);

        raylib.EndDrawing();
        raylib.SwapScreenBuffer();
    }
};
