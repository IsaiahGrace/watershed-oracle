const cli = @import("cli.zig");
const geoCache = @import("geoCache.zig");
const geosCtx = @import("geosCtx.zig");
const server = @import("server.zig");
const sqliteCtx = @import("sqliteCtx.zig");
const sqliteErrors = @import("sqliteErrors.zig");
const telegramBot = @import("telegramBot.zig");
const watershed = @import("watershed.zig");

// There should be a better way to do this, but I'll just add all my files here by hand for now.
// https://github.com/ziglang/zig/issues/16349

test {
    _ = cli;
    _ = geoCache;
    _ = geosCtx;
    _ = server;
    _ = sqliteCtx;
    _ = sqliteErrors;
    _ = telegramBot;
    _ = watershed;
}
