const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("limine", .{
        .root_source_file = b.path("limine.zig"),
    });
}
