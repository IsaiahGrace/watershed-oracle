const args = @import("args.zig");
const Display = @import("DisplayInterface.zig").Display;
const PointSrc = @import("point/interface.zig").PointSrc;
const std = @import("std");
const watershed = @import("watershed.zig");

pub fn main() !void {
    const cliArgs = args.parseArgs() catch |e| {
        switch (e) {
            error.HelpPrinted => return,
            else => return e,
        }
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.log.err("GPA detected a leak!", .{});
    const allocator: std.mem.Allocator = gpa.allocator();

    var watershedStack = try watershed.WatershedStack.init(allocator, cliArgs.databasePath, cliArgs.skipHuc14and16);
    defer watershedStack.deinit();

    var dsp = Display.init(allocator, &watershedStack);
    defer dsp.deinit();
    try dsp.drawSplash();

    var pointSrc = PointSrc.init(allocator, .{ .json = cliArgs.json, .display = &dsp });
    defer pointSrc.deinit();

    // Process points from the pointSrc until there's nothing more to read.
    // Depending on compilation options, this could be stdin, GPS, or the fuzzer.
    while (true) {
        const point = pointSrc.nextPoint() catch |e| {
            switch (e) {
                error.NoMorePoints => break,
                else => return e,
            }
        };

        watershedStack.update(point) catch |e| {
            switch (e) {
                error.pointNotInDataset => {
                    std.log.err("Point not it dataset!", .{});
                },
                else => return e,
            }
        };

        if (cliArgs.json) {
            try watershedStack.printJSON();
        } else if (watershedStack.valid()) {
            try watershedStack.printPoint();
            try watershedStack.printStack();
        }

        if (watershedStack.valid()) {
            try dsp.drawWatershedStack();
        }
    }
}

test "main" {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(@import("pathUtil.zig"));
}
