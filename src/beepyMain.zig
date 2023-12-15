const args = @import("args.zig");
const display = @import("display.zig");
const std = @import("std");
const watershed = @import("watershed.zig");

pub fn main() !void {
    const cliArgs = args.parseArgs(.beepy) catch |e| {
        switch (e) {
            error.HelpPrinted => return,
            else => return e,
        }
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.log.err("GPA detected a leak!", .{});
    const allocator: std.mem.Allocator = gpa.allocator();

    var dsp = display.Display.init(allocator);
    defer dsp.deinit();
    dsp.drawSplash();

    var watershedStack = try watershed.WatershedStack.init(allocator, &dsp, cliArgs.databasePath, cliArgs.skipHuc14and16);
    defer watershedStack.deinit();

    const stdin = std.io.getStdIn().reader();

    var stdinBuffer = std.ArrayList(u8).init(allocator);
    defer stdinBuffer.deinit();

    // Read from stdin until there's nothing more to read.
    while (true) {
        stdin.streamUntilDelimiter(stdinBuffer.writer(), '\n', null) catch |e| {
            switch (e) {
                error.EndOfStream => break,
                else => return e,
            }
        };

        // The WKT reader expects a null terminated string, so we need to add that null byte
        try stdinBuffer.append(0);

        // The @ptrCast() is hacky, but I'm not sure what the "correct" thing to do here is..
        try watershedStack.updateWKT(@ptrCast(stdinBuffer.items));
        try watershedStack.logPoint();
        try watershedStack.logStack();

        try dsp.drawWatershedStack(&watershedStack);

        stdinBuffer.clearRetainingCapacity();
    }

    std.time.sleep(10 * std.time.ns_per_s);
}

test "main" {
    std.testing.refAllDecls(@This());
}
