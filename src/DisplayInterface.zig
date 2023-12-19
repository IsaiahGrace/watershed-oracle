const config = @import("config");
const displayNone = @import("DisplayNone.zig");
const displayRaylib = @import("DisplayRaylib.zig");

pub const Display = switch (config.displayMode) {
    .none => displayNone,
    .windowed, .framebuffer => displayRaylib,
};
