const std = @import("std");

pub fn build(b: *std.Build) void {
    const api_revision = b.option(u32, "api_revision", "Limine API revision to use");
    const allow_deprecated = b.option(bool, "allow_deprecated", "Whether to allow deprecated features");
    const no_pointers = b.option(bool, "no_pointers", "Whether to expose pointers as addresses");

    const config = b.addOptions();
    config.addOption(u32, "api_revision", api_revision orelse 0);
    config.addOption(bool, "allow_deprecated", allow_deprecated orelse false);
    config.addOption(bool, "no_pointers", no_pointers orelse false);

    const module = b.addModule("limine", .{
        .root_source_file = b.path("src/root.zig"),
    });
    module.addImport("config", config.createModule());
}
