const args = @import("args.zig");
const Display = @import("DisplayInterface.zig").Display;
const pointInterface = @import("pointInterface.zig");
const std = @import("std");
const watershed = @import("watershed.zig");

pub fn main() !void {
    const cliArgs = args.parseArgs(.core) catch |e| {
        switch (e) {
            error.HelpPrinted => return,
            else => return e,
        }
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.log.err("GPA detected a leak!", .{});
    const allocator: std.mem.Allocator = gpa.allocator();

    var dummyDsp = Display.init(allocator);
    defer dummyDsp.deinit();

    var watershedStack = try watershed.WatershedStack.init(allocator, &dummyDsp, cliArgs.databasePath, cliArgs.skipHuc14and16);
    defer watershedStack.deinit();

    var pointSrc = pointInterface.PointSrc.init(allocator);
    defer pointSrc.deinit();

    // Read from stdin until there's nothing more to read.
    while (true) {
        const point = pointSrc.nextPoint() catch |e| {
            switch (e) {
                error.NoMoreLocations => break,
                else => return e,
            }
        };
        try watershedStack.update(point);
        try watershedStack.logPoint();
        try watershedStack.logStack();
    }
}

test "main" {
    std.testing.refAllDecls(@This());
}
