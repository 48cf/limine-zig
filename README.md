# limine-zig

Zig bindings for the [The Limine Boot Protocol](https://github.com/limine-bootloader/limine/blob/trunk/PROTOCOL.md).

To use this library, add it to your `build.zig.zon` file manually or use `zig fetch`:

```sh
zig fetch --save git+https://github.com/48cf/limine-zig#trunk
```

Then, import the library in your `build.zig`:

```zig
const limine_zig = b.dependency("limine_zig", .{
    // The API revision of the Limine Boot Protocol to use, if not provided
    // it defaults to 0. Newer revisions may change the behavior of the bootloader.
    .api_revision = 3,
    // Whether to allow using deprecated features of the Limine Boot Protocol.
    // If set to false, the build will fail if deprecated features are used.
    .allow_deprecated = false,
    // Whether to expose pointers in the API. When set to true, any field
    // that is a pointer will be exposed as a raw address instead.
    .no_pointers = false,
});

// Get the Limine module
const limine_module = limine_zig.module("limine");

// Import the Limine module into the kernel
kernel.addImport("limine", limine_module);
```

You can find an example kernel using this library [here](https://github.com/48cf/limine-zig-template).

To use this library, you need at least Zig 0.14.0.
