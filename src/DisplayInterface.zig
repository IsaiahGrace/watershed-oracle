const config = @import("config");
const dummyDisplay = @import("dummyDisplay.zig");
const realDisplay = @import("Display.zig");

pub const Display = if (config.gui) realDisplay.Display else dummyDisplay.Display;
