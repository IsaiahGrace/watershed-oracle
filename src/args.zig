const clap = @import("clap");
const std = @import("std");

const ProgramType = enum {
    core,
    beepy,
};

const Args = struct {
    skipHuc14and16: bool,
    databasePath: []const u8,
};

const params = clap.parseParamsComptime(
    \\-h, --help             Display this help and exit.
    \\-d, --database <str>   Required. The full path to WBD_National_GPKG.gpkg. This path is given directly to sqlite3_open() and does not support the home directory shortcut '~/'.
    \\-s, --skipHuc14and16   Disables searching in HUC levels 14 and 16. These levels are not defined for most of the US. Defaults to false.
);

fn printCoreHelp() !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print("The watershedCore program reads WKT point data line by line from stdin and prints watershed data to stdout.\n", .{});
    try stderr.print("The intended use is to pipe WKT point data into this program from another process like cat, or a GPS tracker.\n\n", .{});
    try stderr.print("Usage:\n", .{});
    try clap.help(stderr, clap.Help, &params, .{});
    try stderr.print("\nExamples:\n", .{});
    try stderr.print("echo \"POINT(-70.386781360 43.5014404586)\" | zig-out/bin/watershedCore --database=/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg\n", .{});
    try stderr.print("cat gps_data_file | zig-out/bin/watershedCore --database=/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg\n\n", .{});
}

fn printBeepyHelp() !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print("The watershedBeepy program TODO Describe the program.\n", .{});
    try stderr.print("TODO, describe how to use the watershedBeepy exe\n\n", .{});
    try stderr.print("Usage:\n", .{});
    try clap.help(stderr, clap.Help, &params, .{});
    try stderr.print("\nExamples:\n", .{});
    try stderr.print("echo \"POINT(-70.386781360 43.5014404586)\" | zig-out/bin/watershedBeepy --database=/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg\n", .{});
    try stderr.print("cat gps_data_file | zig-out/bin/watershedBeepy --database=/home/isaiah/Documents/WBD/WBD_National_GPKG.gpkg\n\n", .{});
}

pub fn parseArgs(programType: ProgramType) !Args {
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0 or res.args.database == null) {
        switch (programType) {
            .core => try printCoreHelp(),
            .beepy => try printBeepyHelp(),
        }
        return error.HelpPrinted;
    }

    return Args{
        .skipHuc14and16 = if (res.args.skipHuc14and16 != 0) true else false,
        .databasePath = res.args.database.?,
    };
}
