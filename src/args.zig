const clap = @import("clap");
const std = @import("std");
const config = @import("config");

const Args = struct {
    skipHuc14and16: bool,
    databasePath: []const u8,
};

const params = clap.parseParamsComptime(
    \\-h, --help             Display this help and exit.
    \\-d, --database <str>   Required. The full path to WBD_National_GPKG.gpkg. This path is given directly to sqlite3_open() and does not support the home directory shortcut '~/'.
    \\-s, --skipHuc14and16   Disables searching in HUC levels 14 and 16. These levels are not defined for most of the US. Defaults to false.
);

const pointProviderText = switch (config.pointProvider) {
    .stdin => "This program reads point data in the form of Well Known Text (WKT) from stdin. One point per line. WKT should be in the form POINT(x y).",
    .fuzzer => "This program randomly generates a starting point in the Ohio or Tennessee watersheds and randomly moves the point in a somewhat NE direction.",
    .gps => "This program uses GPS position data to determine the watershed.",
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
    try stderr.print("cat gps_data_file | zig-out/bin/watershedCore --database=/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg\n\n", .{});
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
        .skipHuc14and16 = if (res.args.skipHuc14and16 != 0) true else false,
        .databasePath = res.args.database.?,
    };
}
