const std = @import("std");
const cincludes = @import("cincludes.zig");

pub export fn foo() u32 {
    return 42;
}

test "foo" {
    try std.testing.expectEqual(foo(), @as(u32, 42));
}
