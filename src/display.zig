const std = @import("std");
const raylib = @cImport(@cInclude("raylib.h"));

// const Display = struct {
// };
pub fn drawShapes() void {
    const screenWidth = 400;
    const screenHeight = 240;

    raylib.InitWindow(screenWidth, screenHeight, "raylib [shapes] example - basic shapes drawing");

    raylib.SetTargetFPS(5);
    raylib.BeginDrawing();

    raylib.ClearBackground(raylib.RAYWHITE);

    raylib.DrawText("some basic shapes available on raylib", 20, 20, 20, raylib.DARKGRAY);
    raylib.DrawCircle(screenWidth / 5, 120, 20, raylib.DARKBLUE);
    raylib.DrawLine(18, 42, screenWidth - 18, 42, raylib.BLACK);
    raylib.EndDrawing();

    std.time.sleep(10 * std.time.ns_per_s);

    raylib.CloseWindow(); // Close window and OpenGL context
}
