const std = @import("std");

pub fn build(b: *std.Build) void {
    const CreateOptions = std.Build.Module.CreateOptions;
    var options: CreateOptions = .{};

    const root_source_path: std.Build.LazyPath = .{ .path = "limine.zig" };
    if (@hasField(CreateOptions, "source_file")) {
        options.source_file = root_source_path;
    } else if (@hasField(CreateOptions, "root_source_file")) {
        options.root_source_file = root_source_path;
    } else {
        @compileError("unsupported zig version");
    }

    _ = b.addModule("limine", options);
}
