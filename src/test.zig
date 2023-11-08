const cli = @import("cli.zig");
const geosCtx = @import("geosCtx.zig");
const gpkg = @import("gpkg.zig");
const server = @import("server.zig");
const sqliteCtx = @import("sqliteCtx.zig");
const sqliteErrors = @import("sqliteErrors.zig");
const telegramBot = @import("telegramBot.zig");
const watershed = @import("watershed.zig");

// There should be a better way to do this, but I'll just add all my files here by hand for now.
// https://github.com/ziglang/zig/issues/16349

test {
    _ = cli;
    _ = geosCtx;
    _ = gpkg;
    _ = server;
    _ = sqliteCtx;
    _ = sqliteErrors;
    _ = telegramBot;
    _ = watershed;
}
