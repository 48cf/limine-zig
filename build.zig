const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("limine", .{ .source_file = .{ .path = "limine.zig" } });
}