const clap = @import("clap");
const config = @import("config");
const std = @import("std");

const Args = struct {
    databasePath: []const u8,
    json: bool,
    skipHuc14and16: bool,
};

const params = clap.parseParamsComptime(
    \\-h, --help             Display this help and exit.
    \\-d, --database <str>   Required. The full path to WBD_National_GPKG.gpkg. This path is given directly to sqlite3_open() and does not support the home directory shortcut '~/'.
    \\-j, --json             Stdin AND stdout data will be formatted with JSON. Stdin objects should have "longitude", "latitude", and "requestId" fields.
    \\-s, --skipHuc14and16   Disables searching in HUC levels 14 and 16. These levels are not defined for most of the US. Defaults to false.
);

const pointProviderText = switch (config.pointProvider) {
    .fuzzer => "This program randomly generates a starting point in the Ohio or Tennessee watersheds and randomly moves the point in a somewhat NE direction.",
    .gps => "This program uses GPS position data to determine the watershed.",
    .gpsMock => "This program reads NMEA codes from stdin to determine the watershed.",
    .scatter => "This program randomly generates points. Most are inside the US, but some are not.",
    .stdin => "This program reads point data in the form of Well Known Text (WKT) from stdin. One point per line. WKT should be in the form POINT(x y).",
};

const displayModeText = switch (config.displayMode) {
    .none => "This program does not include any graphics.",
    .windowed => "This program simulates the screen of the Beepy device.",
    .framebuffer => "This program directly controls the linux framebuffer to draw graphics.",
};

fn printHelp() !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print("{s}\n", .{pointProviderText});
    try stderr.print("{s}\n", .{displayModeText});
    try stderr.print("Usage:\n", .{});
    try clap.help(stderr, clap.Help, &params, .{});
    try stderr.print("\nExamples:\n", .{});
    try stderr.print("echo \"POINT(-70.386781360 43.5014404586)\" | zig-out/bin/watershedOracle --database=/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg\n", .{});
    try stderr.print("cat gps_data_file | zig-out/bin/watershedOracle --database=/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg\n\n", .{});
}

pub fn parseArgs() !Args {
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0 or res.args.database == null) {
        try printHelp();
        return error.HelpPrinted;
    }

    return Args{
        .databasePath = res.args.database.?,
        .json = if (res.args.json != 0) true else false,
        .skipHuc14and16 = if (res.args.skipHuc14and16 != 0) true else false,
    };
}
