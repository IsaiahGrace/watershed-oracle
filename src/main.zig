const clap = @import("clap");
const sqlite = @cImport(@cInclude("sqlite3.h"));
const std = @import("std");
const watershed = @import("watershed.zig");
const display = @import("display.zig");

pub fn main() !void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-d, --database <str>   Required. The full path to WBD_National_GPKG.gpkg. This path is given directly to sqlite3_open() and does not support the home directory shortcut '~/'.
        \\-s, --skipHuc14and16   Disables searching in HUC levels 14 and 16. These levels are not defined for most of the US. Defaults to false.
    );

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0 or res.args.database == null) {
        const stderr = std.io.getStdErr().writer();
        try stderr.print("The WatershedOracleCLI program reads WKT point data line by line from stdin and prints watershed data to stdout.\n", .{});
        try stderr.print("The intended use is to pipe WKT point data into this program from another process like cat, or a GPS tracker.\n\n", .{});
        try stderr.print("Usage:\n", .{});
        try clap.help(stderr, clap.Help, &params, .{});
        try stderr.print("\nExamples:\n", .{});
        try stderr.print("echo \"POINT(-70.386781360 43.5014404586)\" | zig-out/bin/watershedOracle --database=/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg\n", .{});
        try stderr.print("cat gps_data_file | zig-out/bin/watershedOracle --database=/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg\n\n", .{});
        return;
    }

    const skipHuc14and16 = if (res.args.skipHuc14and16 != 0) true else false;

    // Done parsing arguments, lets get to the program!

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.log.err("GPA detected a leak!", .{});
    const allocator: std.mem.Allocator = gpa.allocator();

    var watershedStack = try watershed.WatershedStack.init(allocator, res.args.database.?, skipHuc14and16);
    defer watershedStack.deinit();

    const stdin = std.io.getStdIn().reader();

    var stdinBuffer = std.ArrayList(u8).init(allocator);
    defer stdinBuffer.deinit();

    var dsp = display.Display.init(allocator);
    defer dsp.deinit();

    dsp.drawSplash();

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
