const std = @import("std");

const EnvelopeEnum = enum(u3) {
    none = 0,
    xy = 1,
    xyz = 2,
    xym = 3,
    xyzm = 4,
};

pub const EnvelopeXY = packed struct {
    minx: f64,
    maxx: f64,
    miny: f64,
    maxy: f64,
};

comptime {
    std.debug.assert(@sizeOf(EnvelopeXY) == 32);
}

const EnvelopeXYZ = packed struct {
    minx: f64,
    maxx: f64,
    miny: f64,
    maxy: f64,
    minz: f64,
    maxz: f64,
};

const EnvelopeXYM = packed struct {
    minx: f64,
    maxx: f64,
    miny: f64,
    maxy: f64,
    minm: f64,
    maxm: f64,
};

const EnvelopeXYZM = packed struct {
    minx: f64,
    maxx: f64,
    miny: f64,
    maxy: f64,
    minz: f64,
    maxz: f64,
    minm: f64,
    maxm: f64,
};

const Flags = packed struct {
    b: u1,
    e: u3,
    y: u1,
    x: u1,
    r: u2,
};

comptime {
    std.debug.assert(@bitSizeOf(Flags) == 8);
    std.debug.assert(@sizeOf(Flags) == 1);
}

// Header minus the Envelope, which is variable in size!
pub const Header = packed struct {
    magicG: u8, //0x47
    magicP: u8, //0x50
    version: u8,
    flags: Flags,
    srs_id: u32,
};

pub const headerSize = @sizeOf(Header);

comptime {
    std.debug.assert(headerSize == 8);
}

pub fn envelopeSize(header: *const Header) usize {
    const envelopeEnum: EnvelopeEnum = @enumFromInt(header.flags.e);
    switch (envelopeEnum) {
        .none => return 0,
        .xy => return 32,
        .xyz => return 48,
        .xym => return 48,
        .xyzm => return 64,
    }
}
