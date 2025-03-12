const builtin = @import("builtin");
const config = @import("config");
const std = @import("std");

pub const Arch = enum {
    x86_64,
    aarch64,
    riscv64,
    loongarch64,
};

pub const api_revision = config.api_revision;
pub const arch: Arch = switch (builtin.cpu.arch) {
    .x86_64 => .x86_64,
    .aarch64 => .aarch64,
    .riscv64 => .riscv64,
    .loongarch64 => .loongarch64,
    else => |arch_tag| @compileError("Unsupported architecture: " ++ @tagName(arch_tag)),
};

fn id(a: u64, b: u64) [4]u64 {
    return .{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, a, b };
}

fn LiminePtr(comptime Type: type) type {
    return if (config.no_pointers) u64 else Type;
}

const init_pointer = if (config.no_pointers)
    0
else
    null;

pub const RequestsStartMarker = extern struct {
    marker: [4]u64 = .{
        0xf6b8f4b39de7d1ae,
        0xfab91a6940fcb9cf,
        0x785c6ed015d3e316,
        0x181e920a7852b9d9,
    },
};

pub const RequestsEndMarker = extern struct {
    marker: [2]u64 = .{ 0xadc0e0531bb10d03, 0x9572709f31764c62 },
};

pub const BaseRevision = extern struct {
    magic: [2]u64 = .{ 0xf9562b2d5c95a6c8, 0x6a7b384944536bdc },
    revision: u64,

    pub fn init(revision: u64) @This() {
        return .{ .revision = revision };
    }

    pub fn loadedRevision(self: @This()) u64 {
        return self.magic[1];
    }

    pub fn isValid(self: @This()) bool {
        return self.magic[1] != 0x6a7b384944536bdc;
    }

    pub fn isSupported(self: @This()) bool {
        return self.revision == 0;
    }
};

pub const Uuid = extern struct {
    a: u32,
    b: u16,
    c: u16,
    d: [8]u8,
};

pub const MediaType = enum(u32) {
    generic = 0,
    optical = 1,
    tftp = 2,
    _,
};

const LimineFileV1 = extern struct {
    revision: u64,
    address: LiminePtr(*align(4096) anyopaque),
    size: u64,
    path: LiminePtr([*:0]u8),
    cmdline: LiminePtr([*:0]u8),
    media_type: MediaType,
    unused: u32,
    tftp_ip: u32,
    tftp_port: u32,
    partition_index: u32,
    mbr_disk_id: u32,
    gpt_disk_uuid: Uuid,
    gpt_part_uuid: Uuid,
    part_uuid: Uuid,
};

const LimineFileV2 = extern struct {
    revision: u64,
    address: LiminePtr(*align(4096) anyopaque),
    size: u64,
    path: LiminePtr([*:0]u8),
    string: LiminePtr([*:0]u8),
    media_type: MediaType,
    unused: u32,
    tftp_ip: u32,
    tftp_port: u32,
    partition_index: u32,
    mbr_disk_id: u32,
    gpt_disk_uuid: Uuid,
    gpt_part_uuid: Uuid,
    part_uuid: Uuid,
};

pub const File = if (config.api_revision >= 3)
    LimineFileV2
else
    LimineFileV1;

// Boot info

pub const BootloaderInfoResponse = extern struct {
    revision: u64,
    name: LiminePtr([*:0]u8),
    version: LiminePtr([*:0]u8),
};

pub const BootloaderInfoRequest = extern struct {
    id: [4]u64 = id(0xf55038d8e2a1202f, 0x279426fcf5f59740),
    revision: u64 = 0,
    response: LiminePtr(?*BootloaderInfoResponse) = init_pointer,
};

// Executable command line

pub const ExecutableCmdlineResponse = extern struct {
    revision: u64,
    cmdline: LiminePtr([*:0]u8),
};

pub const ExecutableCmdlineRequest = extern struct {
    id: [4]u64 = id(0x4b161536e598651e, 0xb390ad4a2f1f303a),
    revision: u64 = 0,
    response: LiminePtr(?*ExecutableCmdlineResponse) = init_pointer,
};

// Firmware type

pub const FirmwareType = enum(u64) {
    x86_bios = 0,
    uefi32 = 1,
    uefi64 = 2,
    sbi = 3,
    _,
};

pub const FirmwareTypeResponse = extern struct {
    revision: u64,
    firmware_type: FirmwareType,
};

pub const FirmwareTypeRequest = extern struct {
    id: [4]u64 = id(0x8c2f75d90bef28a8, 0x7045a4688eac00c3),
    revision: u64 = 0,
    response: LiminePtr(?*FirmwareTypeResponse) = init_pointer,
};

// Stack size

pub const StackSizeResponse = extern struct {
    revision: u64,
};

pub const StackSizeRequest = extern struct {
    id: [4]u64 = id(0x224ef0460a8e8926, 0xe1cb0fc25f46ea3d),
    revision: u64 = 0,
    response: LiminePtr(?*StackSizeResponse) = init_pointer,
    stack_size: u64,
};

// HHDM

pub const HhdmResponse = extern struct {
    revision: u64,
    offset: u64,
};

pub const HhdmRequest = extern struct {
    id: [4]u64 = id(0x48dcf1cb8ad2b852, 0x63984e959a98244b),
    revision: u64 = 0,
    response: LiminePtr(?*HhdmResponse) = init_pointer,
};

// Framebuffer

pub const FramebufferMemoryModel = enum(u8) {
    rgb = 1,
    _,
};

pub const VideoMode = extern struct {
    pitch: u64,
    width: u64,
    height: u64,
    bpp: u16,
    memory_model: FramebufferMemoryModel,
    red_mask_size: u8,
    red_mask_shift: u8,
    green_mask_size: u8,
    green_mask_shift: u8,
    blue_mask_size: u8,
    blue_mask_shift: u8,
};

pub const Framebuffer = extern struct {
    address: LiminePtr(*anyopaque),
    width: u64,
    height: u64,
    pitch: u64,
    bpp: u16,
    memory_model: FramebufferMemoryModel,
    red_mask_size: u8,
    red_mask_shift: u8,
    green_mask_size: u8,
    green_mask_shift: u8,
    blue_mask_size: u8,
    blue_mask_shift: u8,
    edid_size: u64,
    edid: LiminePtr(?*anyopaque),
    // Response revision 1
    mode_count: u64,
    modes: LiminePtr([*]*VideoMode),

    /// Helper function to retrieve the EDID data as a slice.
    /// This function will return null if the EDID size is 0 or if
    /// the EDID pointer is null.
    pub fn getEdid(self: @This()) ?[*]u8 {
        if (self.edid_size == 0 or self.edid == null) {
            return null;
        }
        return @as([*]u8, self.edid.?)[0..self.edid_size];
    }

    /// Helper function to retrieve a slice of the modes array.
    /// This function is only available since revision 1 of the response and
    /// will return an error if called with an older response. This is to
    /// prevent the user from possibly accessing uninitialized memory.
    pub fn getModes(self: @This(), response: *FramebufferResponse) ![]*VideoMode {
        if (response.revision < 1) {
            return error.NotSupported;
        }
        return self.modes[0..self.mode_count];
    }
};

pub const FramebufferResponse = extern struct {
    revision: u64,
    framebuffer_count: u64,
    framebuffers: LiminePtr(?[*]*Framebuffer),

    /// Helper function to retrieve a slice of the framebuffers array.
    /// This function will return null if the framebuffer count is 0 or if
    /// the framebuffers pointer is null.
    pub fn getFramebuffers(self: @This()) []*Framebuffer {
        if (self.framebuffer_count == 0 or self.framebuffers == null) {
            return &.{};
        }
        return self.framebuffers.?[0..self.framebuffer_count];
    }
};

pub const FramebufferRequest = extern struct {
    id: [4]u64 = id(0x9d5827dcd881dd75, 0xa3148604f6fab11b),
    revision: u64 = 1,
    response: LiminePtr(?*FramebufferResponse) = init_pointer,
};

// Terminal

const TerminalDeprecated = struct {
    const deprecation_message =
        \\The Terminal feature was deprecated and is no longer available.
        \\Kernels are encouraged to manually implement terminal support
        \\using the Framebuffer feature instead. If you need an easy to
        \\integrate solution, consider using https://github.com/mintsuki/flanterm.
    ;

    pub const TerminalCallbackType = @compileError(deprecation_message);
    pub const TerminalCallbackEscapeParams = @compileError(deprecation_message);
    pub const TerminalCallbackPosReportParams = @compileError(deprecation_message);
    pub const TerminalCallbackKbdLedsState = @compileError(deprecation_message);
    pub const TerminalCallbackKbdLedsParams = @compileError(deprecation_message);
    pub const TerminalWrite = @compileError(deprecation_message);
    pub const TerminalCallback = @compileError(deprecation_message);
    pub const Terminal = @compileError(deprecation_message);
    pub const TerminalResponse = @compileError(deprecation_message);
    pub const TerminalRequest = @compileError(deprecation_message);
};

const TerminalFeature = struct {
    pub const TerminalCallbackType = enum(u64) {
        dec = 10,
        bell = 20,
        private_id = 30,
        status_report = 40,
        pos_report = 50,
        kbd_leds = 60,
        mode = 70,
        linux = 80,
        _,
    };

    pub const TerminalCallbackEscapeParams = struct {
        a1: u64,
        a2: u64,
        a3: u64,

        /// Initialize a TerminalCallbackEscapeParams struct, which is used for
        /// decoding the parameters of the terminal callbacks that handle escape sequences.
        pub fn init(a1: u64, a2: u64, a3: u64) @This() {
            return .{ .a1 = a1, .a2 = a2, .a3 = a3 };
        }

        /// Retrieve the array of values passed to the escape sequence.
        pub fn values(self: @This()) []u32 {
            const values_ptr: [*]u32 = @intFromPtr(self.a2);
            return values_ptr[0..self.a1];
        }

        /// Retrieve the final character in a DEC or ECMA-48 Mode Switch
        /// escape sequence.
        /// This is the character that is used to determine the type of
        /// sequence that was sent, usually 'h' or 'l'.
        pub fn finalChar(self: @This()) u8 {
            return @intCast(self.a3);
        }
    };

    pub const TerminalCallbackPosReportParams = struct {
        a1: u64,
        a2: u64,

        /// Initialize a TerminalCallbackPosReportParams struct, which is used for
        /// decoding the parameters of a position report terminal callback.
        pub fn init(a1: u64, a2: u64) @This() {
            return .{ .a1 = a1, .a2 = a2 };
        }

        /// Retrieve the X position of the cursor.
        pub fn x(self: @This()) u64 {
            return self.a1;
        }

        /// Retrieve the Y position of the cursor.
        pub fn y(self: @This()) u64 {
            return self.a2;
        }
    };

    pub const TerminalCallbackKbdLedsState = enum(u64) {
        clear_all = 0,
        set_scroll_lock = 1,
        set_num_lock = 2,
        set_caps_lock = 3,
        _,
    };

    pub const TerminalCallbackKbdLedsParams = struct {
        a1: u64,

        /// Initialize a TerminalCallbackKbdLedsParams struct, which is used for
        /// decoding the parameters of a keyboard LEDs terminal callback.
        pub fn init(a1: u64) @This() {
            return .{ .a1 = a1 };
        }

        /// Retrieve the state of the Caps Lock LED.
        pub fn state(self: @This()) TerminalCallbackKbdLedsState {
            return @enumFromInt(self.a1);
        }
    };

    pub const TerminalWrite = *const fn (*Terminal, [*]const u8, u64) callconv(.c) void;

    pub const TerminalCallback = *const fn (*Terminal, TerminalCallbackType, u64, u64, u64) callconv(.c) void;

    pub const Terminal = extern struct {
        columns: u64,
        rows: u64,
        framebuffer: LiminePtr(?*Framebuffer),
    };

    pub const TerminalResponse = extern struct {
        revision: u64,
        terminal_count: u64,
        terminals: LiminePtr(?[*]*Terminal),
        write_fn: LiminePtr(TerminalWrite),

        /// Helper function to retrieve a slice of the terminals array.
        /// This function will return null if the terminal count is 0 or if
        /// the terminals pointer is null.
        pub fn getTerminals(self: @This()) []*Terminal {
            if (self.terminal_count == 0 or self.terminals == null) {
                return &.{};
            }
            return self.terminals.?[0..self.terminal_count];
        }

        /// Helper function to write to a terminal.
        pub fn write(self: @This(), terminal: *Terminal, data: []const u8) void {
            const write_fn: TerminalWrite = if (config.no_pointers)
                @ptrFromInt(self.write_fn)
            else
                self.write_fn;

            write_fn(terminal, data.ptr, data.len);
        }
    };

    pub const TerminalRequest = extern struct {
        id: [4]u64 = id(0xc8ac59310c2b0844, 0xa68d0c7265d38878),
        revision: u64 = 0,
        response: LiminePtr(?*TerminalResponse) = init_pointer,
        callback: LiminePtr(?TerminalCallback),
    };
};

pub usingnamespace if (config.allow_deprecated)
    TerminalFeature
else
    TerminalDeprecated;

// Paging mode

pub const PagingMode = switch (arch) {
    .x86_64 => enum(u64) {
        @"4lvl",
        @"5lvl",
        _,

        const min: @This() = .@"4lvl";
        const max: @This() = .@"5lvl";
        const default: @This() = .@"4lvl";
    },
    .aarch64 => enum(u64) {
        @"4lvl",
        @"5lvl",
        _,

        const min: @This() = .@"4lvl";
        const max: @This() = .@"5lvl";
        const default: @This() = .@"4lvl";
    },
    .riscv64 => enum(u64) {
        sv39,
        sv48,
        sv57,
        _,

        const min: @This() = .sv39;
        const max: @This() = .sv57;
        const default: @This() = .sv48;
    },
    .loongarch64 => enum(u64) {
        @"4lvl",
        _,

        const min: @This() = .@"4lvl";
        const max: @This() = .@"4lvl";
        const default: @This() = .@"4lvl";
    },
};

pub const PagingModeResponse = extern struct {
    revision: u64,
    mode: PagingMode,
};

pub const PagingModeRequest = extern struct {
    id: [4]u64 = id(0x95c1a0edab0944cb, 0xa4e5cb3842f7488a),
    revision: u64 = 0,
    response: LiminePtr(?*PagingModeResponse) = init_pointer,
    mode: PagingMode = .default,
    max_mode: PagingMode = .max,
    min_mode: PagingMode = .min,
};

// 5-level paging

const FiveLevelPagingDeprecated = struct {
    const deprecation_message =
        \\The 5-level paging feature was deprecated and is no longer available.
        \\Kernels are encouraged to manually request 5-level paging support
        \\using the Paging mode feature instead.
    ;

    pub const FiveLevelPagingResponse = @compileError(deprecation_message);
    pub const FiveLevelPagingRequest = @compileError(deprecation_message);
};

const FiveLevelPagingFeature = struct {
    pub const FiveLevelPagingResponse = extern struct {
        revision: u64,
    };

    pub const FiveLevelPagingRequest = extern struct {
        id: [4]u64 = id(0x94469551da9b3192, 0xebe5e86db7382888),
        revision: u64 = 0,
        response: LiminePtr(?*FiveLevelPagingResponse) = init_pointer,
    };
};

pub usingnamespace if (config.allow_deprecated)
    FiveLevelPagingFeature
else
    FiveLevelPagingDeprecated;

// MP (formerly SMP)

pub const GotoAddress = *const fn (*SmpMpInfo) callconv(.c) noreturn;

const SmpMpFlags = switch (arch) {
    .x86_64 => packed struct(u32) {
        x2apic: bool = false,
        reserved: u31 = 0,
    },
    .aarch64, .riscv64, .loongarch64 => packed struct(u64) {
        reserved: u64 = 0,
    },
};

const SmpMpInfo = switch (arch) {
    .x86_64 => extern struct {
        processor_id: u32,
        lapic_id: u32,
        reserved: u64,
        goto_address: LiminePtr(?GotoAddress),
        extra_argument: u64,
    },
    .aarch64 => extern struct {
        processor_id: u32,
        mpidr: u64,
        reserved: u64,
        goto_address: LiminePtr(?GotoAddress),
        extra_argument: u64,
    },
    .riscv64 => extern struct {
        processor_id: u64,
        hartid: u64,
        reserved: u64,
        goto_address: LiminePtr(?GotoAddress),
        extra_argument: u64,
    },
    .loongarch64 => extern struct {
        reserved: u64,
    },
};

const SmpMpResponse = switch (arch) {
    .x86_64 => extern struct {
        revision: u64,
        flags: SmpMpFlags,
        bsp_lapic_id: u32,
        cpu_count: u64,
        cpus: LiminePtr(?[*]*SmpMpInfo),

        /// Helper function to retrieve a slice of the CPUs array.
        /// This function will return null if the CPU count is 0 or if
        /// the CPUs pointer is null.
        pub fn getCpus(self: @This()) []*SmpMpInfo {
            if (self.cpu_count == 0 or self.cpus == null) {
                return &.{};
            }
            return self.cpus.?[0..self.cpu_count];
        }
    },
    .aarch64 => extern struct {
        revision: u64,
        flags: SmpMpFlags,
        bsp_mpidr: u64,
        cpu_count: u64,
        cpus: LiminePtr(?[*]*SmpMpInfo),

        /// Helper function to retrieve a slice of the CPUs array.
        /// This function will return null if the CPU count is 0 or if
        /// the CPUs pointer is null.
        pub fn getCpus(self: @This()) []*SmpMpInfo {
            if (self.cpu_count == 0 or self.cpus == null) {
                return &.{};
            }
            return self.cpus.?[0..self.cpu_count];
        }
    },
    .riscv64 => extern struct {
        revision: u64,
        flags: SmpMpFlags,
        bsp_hartid: u64,
        cpu_count: u64,
        cpus: LiminePtr(?[*]*SmpMpInfo),

        /// Helper function to retrieve a slice of the CPUs array.
        /// This function will return null if the CPU count is 0 or if
        /// the CPUs pointer is null.
        pub fn getCpus(self: @This()) []*SmpMpInfo {
            if (self.cpu_count == 0 or self.cpus == null) {
                return &.{};
            }
            return self.cpus.?[0..self.cpu_count];
        }
    },
    .loongarch64 => extern struct {
        cpu_count: u64,
        cpus: LiminePtr(?[*]*SmpMpInfo),

        /// Helper function to retrieve a slice of the CPUs array.
        /// This function will return null if the CPU count is 0 or if
        /// the CPUs pointer is null.
        pub fn getCpus(self: @This()) []*SmpMpInfo {
            if (self.cpu_count == 0 or self.cpus == null) {
                return &.{};
            }
            return self.cpus.?[0..self.cpu_count];
        }
    },
};

const SmpMpRequest = extern struct {
    id: [4]u64 = id(0x95a67b819a1b857e, 0xa0b61b723b6a73e0),
    revision: u64 = 0,
    response: LiminePtr(?*SmpMpResponse) = init_pointer,
    // The `flags` field in the request is 64-bit on *all* platforms, even
    // though the flags enum is 32-bit on x86_64. This is to ensure that the
    // struct is not too small on x86_64 there is a `reserved: u32` field after it.
    flags: SmpMpFlags = .{},
    reserved: u32 = 0,
};

const MpFeature = struct {
    pub const MpFlags = SmpMpFlags;
    pub const MpInfo = SmpMpInfo;
    pub const MpResponse = SmpMpResponse;
    pub const MpRequest = SmpMpRequest;
};

const SmpFeature = struct {
    pub const SmpFlags = SmpMpFlags;
    pub const SmpInfo = SmpMpInfo;
    pub const SmpResponse = SmpMpResponse;
    pub const SmpRequest = SmpMpRequest;
};

pub usingnamespace if (config.api_revision >= 1)
    MpFeature
else
    SmpFeature;

// Memory map

const MemoryMapTypeV1 = enum(u64) {
    usable = 0,
    reserved = 1,
    acpi_reclaimable = 2,
    acpi_nvs = 3,
    bad_memory = 4,
    bootloader_reclaimable = 5,
    kernel_and_modules = 6,
    framebuffer = 7,
    _,
};

const MemoryMapTypeV2 = enum(u64) {
    usable = 0,
    reserved = 1,
    acpi_reclaimable = 2,
    acpi_nvs = 3,
    bad_memory = 4,
    bootloader_reclaimable = 5,
    executable_and_modules = 6,
    framebuffer = 7,
    _,
};

pub const MemoryMapType = if (config.api_revision >= 2)
    MemoryMapTypeV2
else
    MemoryMapTypeV1;

pub const MemoryMapEntry = extern struct {
    base: u64,
    length: u64,
    type: MemoryMapType,
};

pub const MemoryMapResponse = extern struct {
    revision: u64,
    entry_count: u64,
    entries: LiminePtr(?[*]*MemoryMapEntry),

    /// Helper function to retrieve a slice of the entries array.
    /// This function will return null if the entry count is 0 or if
    /// the entries pointer is null.
    pub fn getEntries(self: @This()) []*MemoryMapEntry {
        if (self.entry_count == 0 or self.entries == null) {
            return &.{};
        }
        return self.entries.?[0..self.entry_count];
    }
};

pub const MemoryMapRequest = extern struct {
    id: [4]u64 = id(0x67cf3d9d378a806f, 0xe304acdfc50c3c62),
    revision: u64 = 0,
    response: LiminePtr(?*MemoryMapResponse) = init_pointer,
};

// Entry point

pub const EntryPoint = *const fn () callconv(.c) noreturn;

pub const EntryPointResponse = extern struct {
    revision: u64,
};

pub const EntryPointRequest = extern struct {
    id: [4]u64 = id(0x13d86c035a1cd3e1, 0x2b0caa89d8f3026a),
    revision: u64 = 0,
    response: LiminePtr(?*EntryPointResponse) = init_pointer,
    entry: LiminePtr(EntryPoint),
};

// Executable file (formerly Kernel file)

const ExecutableFileFeature = struct {
    pub const ExecutableFileResponse = extern struct {
        revision: u64,
        executable_file: LiminePtr(*File),
    };

    pub const ExecutableFileRequest = extern struct {
        id: [4]u64 = id(0xad97e90e83f1ed67, 0x31eb5d1c5ff23b69),
        revision: u64 = 0,
        response: LiminePtr(?*ExecutableFileResponse) = init_pointer,
    };
};

const KernelFileFeature = struct {
    pub const KernelFileResponse = extern struct {
        revision: u64,
        kernel_file: LiminePtr(*File),
    };

    pub const KernelFileRequest = extern struct {
        id: [4]u64 = id(0xad97e90e83f1ed67, 0x31eb5d1c5ff23b69),
        revision: u64 = 0,
        response: LiminePtr(?*KernelFileResponse) = init_pointer,
    };
};

pub usingnamespace if (config.api_revision >= 2)
    ExecutableFileFeature
else
    KernelFileFeature;

// Module

pub const InternalModuleFlag = packed struct(u64) {
    required: bool,
    compressed: bool,
    reserved: u62 = 0,
};

const InternalModuleV1 = extern struct {
    path: LiminePtr([*:0]const u8),
    cmdline: LiminePtr([*:0]const u8),
    flags: InternalModuleFlag,
};

const InternalModuleV2 = extern struct {
    path: LiminePtr([*:0]const u8),
    string: LiminePtr([*:0]const u8),
    flags: InternalModuleFlag,
};

pub const InternalModule = if (config.api_revision >= 3)
    InternalModuleV2
else
    InternalModuleV1;

pub const ModuleResponse = extern struct {
    revision: u64,
    module_count: u64,
    modules: LiminePtr(?[*]*File),

    /// Helper function to retrieve a slice of the modules array.
    /// This function will return null if the module count is 0 or if
    /// the modules pointer is null.
    pub fn getModules(self: @This()) []*File {
        if (self.module_count == 0 or self.modules == null) {
            return &.{};
        }
        return self.modules.?[0..self.module_count];
    }
};

pub const ModuleRequest = extern struct {
    id: [4]u64 = id(0x3e7e279702be32af, 0xca1c4f3bd1280cee),
    revision: u64 = 1,
    response: LiminePtr(?*ModuleResponse) = init_pointer,
    // Request revision 1
    internal_module_count: u64 = 0,
    internal_modules: LiminePtr(?[*]const *const InternalModule) =
        if (config.no_pointers) 0 else null,
};

// RSDP

const RsdpResponseV1 = extern struct {
    revision: u64,
    address: LiminePtr(*anyopaque),
};

const RsdpResponseV2 = extern struct {
    revision: u64,
    address: u64,
};

/// The response to the RSDP request. If the base revision is 1 or higher,
/// the response will contain physical addresses to the RSDP, otherwise
/// the response will contain virtual addresses to the RSDP.
pub const RsdpResponse = if (config.api_revision >= 1)
    RsdpResponseV2
else
    RsdpResponseV1;

pub const RsdpRequest = extern struct {
    id: [4]u64 = id(0xc5e77b6b397e7b43, 0x27637845accdcf3c),
    revision: u64 = 0,
    response: LiminePtr(?*RsdpResponse) = init_pointer,
};

// SMBIOS

const SmBiosResponseV1 = extern struct {
    revision: u64,
    entry_32: LiminePtr(?*anyopaque),
    entry_64: LiminePtr(?*anyopaque),
};

const SmBiosResponseV2 = extern struct {
    revision: u64,
    entry_32: u64,
    entry_64: u64,
};

/// The response to the SMBIOS request. If the base revision is 3 or higher,
/// the response will contain physical addresses to the SMBIOS entries, otherwise
/// the response will contain virtual addresses to the SMBIOS entries.
pub const SmBiosResponse = if (config.api_revision >= 1)
    SmBiosResponseV2
else
    SmBiosResponseV1;

pub const SmBiosRequest = extern struct {
    id: [4]u64 = id(0x9e9046f11e095391, 0xaa4a520fefbde5ee),
    revision: u64 = 0,
    response: LiminePtr(?*SmBiosResponse) = init_pointer,
};

// EFI system table

///
const EfiSystemTableResponseV1 = extern struct {
    revision: u64,
    address: LiminePtr(?*std.os.uefi.tables.SystemTable),
};

const EfiSystemTableResponseV2 = extern struct {
    revision: u64,
    address: u64,
};

/// The response to the EFI system table request. If the base revision is 3
/// or higher, the response will contain a physical address to the system table,
/// otherwise the response will contain a virtual address to the system table.
pub const EfiSystemTableResponse = if (config.api_revision >= 1)
    EfiSystemTableResponseV2
else
    EfiSystemTableResponseV1;

pub const EfiSystemTableRequest = extern struct {
    id: [4]u64 = id(0x5ceba5163eaaf6d6, 0x0a6981610cf65fcc),
    revision: u64 = 0,
    response: LiminePtr(?*EfiSystemTableResponse) = init_pointer,
};

// EFI memory map

pub const EfiMemoryMapResponse = extern struct {
    revision: u64,
    memmap: LiminePtr(*anyopaque),
    memmap_size: u64,
    desc_size: u64,
    desc_version: u64,
};

pub const EfiMemoryMapRequest = extern struct {
    id: [4]u64 = id(0x7df62a431d6872d5, 0xa4fcdfb3e57306c8),
    revision: u64 = 0,
    response: LiminePtr(?*EfiMemoryMapResponse) = init_pointer,
};

// Date at boot (formerly Boot time)

const DateAtBootFeature = struct {
    pub const DateAtBootResponse = extern struct {
        revision: u64,
        timestamp: i64,
    };

    pub const DateAtBootRequest = extern struct {
        id: [4]u64 = id(0x502746e184c088aa, 0xfbc5ec83e6327893),
        revision: u64 = 0,
        response: LiminePtr(?*DateAtBootResponse) = init_pointer,
    };
};

const BootTimeFeature = struct {
    pub const BootTimeResponse = extern struct {
        revision: u64,
        boot_time: i64,
    };

    pub const BootTimeRequest = extern struct {
        id: [4]u64 = id(0x502746e184c088aa, 0xfbc5ec83e6327893),
        revision: u64 = 0,
        response: LiminePtr(?*BootTimeResponse) = init_pointer,
    };
};

pub usingnamespace if (config.api_revision >= 3)
    DateAtBootFeature
else
    BootTimeFeature;

// Executable address (formerly Kernel address)

const ExecutableAddressFeature = struct {
    pub const ExecutableAddressResponse = extern struct {
        revision: u64,
        physical_base: u64,
        virtual_base: u64,
    };

    pub const ExecutableAddressRequest = extern struct {
        id: [4]u64 = id(0x71ba76863cc55f63, 0xb2644a48c516a487),
        revision: u64 = 0,
        response: LiminePtr(?*ExecutableAddressResponse) = init_pointer,
    };
};

const KernelAddressFeature = struct {
    pub const KernelAddressResponse = extern struct {
        revision: u64,
        physical_base: u64,
        virtual_base: u64,
    };

    pub const KernelAddressRequest = extern struct {
        id: [4]u64 = id(0x71ba76863cc55f63, 0xb2644a48c516a487),
        revision: u64 = 0,
        response: LiminePtr(?*KernelAddressResponse) = init_pointer,
    };
};

pub usingnamespace if (config.api_revision >= 2)
    ExecutableAddressFeature
else
    KernelAddressFeature;

// Device Tree Blob

pub const DtbResponse = extern struct {
    revision: u64,
    dtb_ptr: LiminePtr(*anyopaque),
};

pub const DtbRequest = extern struct {
    id: [4]u64 = id(0xb40ddb48fb54bac7, 0x545081493f81ffb7),
    revision: u64 = 0,
    response: LiminePtr(?*DtbResponse) = init_pointer,
};

// RISC-V Boot Hart ID

pub const RiscvBootHartIdResponse = extern struct {
    revision: u64,
    bsp_hartid: u64,
};

pub const RiscvBootHartIdRequest = extern struct {
    id: [4]u64 = id(0x1369359f025525f9, 0x2ff2a56178391bb6),
    revision: u64 = 0,
    response: LiminePtr(?*RiscvBootHartIdResponse) = init_pointer,
};

comptime {
    if (config.api_revision > 3) {
        @compileError("Limine API revision must be 3 or lower");
    }

    std.testing.refAllDeclsRecursive(@This());
}
