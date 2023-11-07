const std = @import("std");

pub const EnvelopeXY = extern struct {
    minx: f64,
    maxx: f64,
    miny: f64,
    maxy: f64,
};

// Header minus the Envelope, which is variable in size!
pub const Header = extern struct {
    magicG: u8, //0x47
    magicP: u8, //0x50
    version: u8,
    flags: u8,
    srs_id: u32,
};

// Our GeoPackage data always contains an XY envelope
pub const HeaderAndEnvelopeXY = extern struct {
    header: Header,
    envelopeXY: EnvelopeXY,
};

comptime {
    std.debug.assert(@sizeOf(Header) == 8);
    std.debug.assert(@sizeOf(EnvelopeXY) == 32);
    std.debug.assert(@sizeOf(HeaderAndEnvelopeXY) == 40);
}
