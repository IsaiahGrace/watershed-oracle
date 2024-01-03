const config = @import("config");

pub const Display = switch (config.displayMode) {
    .none => @import("DisplayNone.zig"),
    .windowed, .framebuffer => @import("DisplayRaylib.zig"),
};
