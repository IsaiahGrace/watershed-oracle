const std = @import("std");
const raylib = @cImport(@cInclude("raylib.h"));

const screenWidth = 400;
const screenHeight = 240;

// const Display = struct {
// };
pub fn raylibTest() void {
    raylib.InitWindow(screenWidth, screenHeight, "Beepy LCD display");

    // TODO: figure out if this is really needed...
    raylib.SetTargetFPS(5);

    raylib.BeginDrawing();

    raylib.ClearBackground(raylib.RAYWHITE);

    raylib.DrawText("Watershed Oracle", 20, 10, 20, raylib.BLACK);
    raylib.DrawLine(18, 35, screenWidth - 18, 35, raylib.BLACK);

    raylib.DrawText("01", 10, 40, 10, raylib.BLACK);
    raylib.DrawText("0106", 10, 70, 10, raylib.BLACK);
    raylib.DrawText("010600", 10, 100, 10, raylib.BLACK);
    raylib.DrawText("01060001", 10, 130, 10, raylib.BLACK);
    raylib.DrawText("0106000105", 10, 160, 10, raylib.BLACK);
    raylib.DrawText("010600010502", 10, 190, 10, raylib.BLACK);

    raylib.DrawText("New England Region", 20, 50, 20, raylib.BLACK);
    raylib.DrawText("Saco", 20, 80, 20, raylib.BLACK);
    raylib.DrawText("Saco", 20, 110, 20, raylib.BLACK);
    raylib.DrawText("Presumpscot", 20, 140, 20, raylib.BLACK);
    raylib.DrawText("Saco Bay-Frontal Atlantic Ocean", 20, 170, 20, raylib.BLACK);
    raylib.DrawText("Goosefare Brook-Frontal Saco Bay", 20, 200, 20, raylib.BLACK);

    raylib.EndDrawing();
    std.time.sleep(20 * std.time.ns_per_s);
    raylib.CloseWindow();
}
