const builtin = @import("builtin");
const std = @import("std");

pub const Arch = enum {
    x86_64,
    aarch64,
    riscv64,
    loongarch64,
};

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

pub const File = extern struct {
    revision: u64,
    address: *align(4096) anyopaque,
    size: u64,
    path: [*:0]u8,
    string: [*:0]u8,
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

// Boot info

pub const BootloaderInfoResponse = extern struct {
    revision: u64,
    name: [*:0]u8,
    version: [*:0]u8,
};

pub const BootloaderInfoRequest = extern struct {
    id: [4]u64 = id(0xf55038d8e2a1202f, 0x279426fcf5f59740),
    revision: u64 = 0,
    response: ?*BootloaderInfoResponse = null,
};

// Executable command line

pub const ExecutableCmdlineResponse = extern struct {
    revision: u64,
    cmdline: [*:0]u8,
};

pub const ExecutableCmdlineRequest = extern struct {
    id: [4]u64 = id(0x4b161536e598651e, 0xb390ad4a2f1f303a),
    revision: u64 = 0,
    response: ?*ExecutableCmdlineResponse = null,
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
    response: ?*FirmwareTypeResponse = null,
};

// Stack size

pub const StackSizeResponse = extern struct {
    revision: u64,
};

pub const StackSizeRequest = extern struct {
    id: [4]u64 = id(0x224ef0460a8e8926, 0xe1cb0fc25f46ea3d),
    revision: u64 = 0,
    response: ?*StackSizeResponse = null,
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
    response: ?*HhdmResponse = null,
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
    address: *anyopaque,
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
    edid: [*]u8,
    // Response revision 1
    mode_count: u64,
    modes: [*]*VideoMode,
};

pub const FramebufferResponse = extern struct {
    revision: u64,
    framebuffer_count: u64,
    framebuffers: ?[*]*Framebuffer,

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
    response: ?*FramebufferResponse = null,
};

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
    response: ?*PagingModeResponse = null,
    mode: PagingMode = .default,
    max_mode: PagingMode = .max,
    min_mode: PagingMode = .min,
};

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
        goto_address: ?GotoAddress,
        extra_argument: u64,
    },
    .aarch64 => extern struct {
        processor_id: u32,
        mpidr: u64,
        reserved: u64,
        goto_address: ?GotoAddress,
        extra_argument: u64,
    },
    .riscv64 => extern struct {
        processor_id: u64,
        hartid: u64,
        reserved: u64,
        goto_address: ?GotoAddress,
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
        cpus: ?[*]*SmpMpInfo,

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
        cpus: ?[*]*SmpMpInfo,

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
        cpus: ?[*]*SmpMpInfo,

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
        cpus: ?[*]*SmpMpInfo,

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
    response: ?*SmpMpResponse = null,
    // The `flags` field in the request is 64-bit on *all* platforms, even
    // though the flags enum is 32-bit on x86_64. This is to ensure that the
    // struct is not too small on x86_64 there is a `reserved: u32` field after it.
    flags: SmpMpFlags = .{},
    reserved: u32 = 0,
};

pub const SmpFlags = SmpMpFlags;
pub const SmpInfo = SmpMpInfo;
pub const SmpResponse = SmpMpResponse;
pub const SmpRequest = SmpMpRequest;

// Memory map

pub const MemoryMapType = enum(u64) {
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

pub const MemoryMapEntry = extern struct {
    base: u64,
    length: u64,
    type: MemoryMapType,
};

pub const MemoryMapResponse = extern struct {
    revision: u64,
    entry_count: u64,
    entries: ?[*]*MemoryMapEntry,

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
    response: ?*MemoryMapResponse = null,
};

// Entry point

pub const EntryPoint = *const fn () callconv(.c) noreturn;

pub const EntryPointResponse = extern struct {
    revision: u64,
};

pub const EntryPointRequest = extern struct {
    id: [4]u64 = id(0x13d86c035a1cd3e1, 0x2b0caa89d8f3026a),
    revision: u64 = 0,
    response: ?*EntryPointResponse = null,
    entry: EntryPoint,
};

// Executable file (formerly Kernel file)

pub const ExecutableFileResponse = extern struct {
    revision: u64,
    executable_file: *File,
};

pub const ExecutableFileRequest = extern struct {
    id: [4]u64 = id(0xad97e90e83f1ed67, 0x31eb5d1c5ff23b69),
    revision: u64 = 0,
    response: ?*ExecutableFileResponse = null,
};

// Module

pub const InternalModuleFlag = packed struct(u64) {
    required: bool,
    compressed: bool,
    reserved: u62 = 0,
};

pub const InternalModule = extern struct {
    path: [*:0]const u8,
    string: [*:0]const u8,
    flags: InternalModuleFlag,
};

pub const ModuleResponse = extern struct {
    revision: u64,
    module_count: u64,
    modules: ?[*]*File,

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
    response: ?*ModuleResponse = null,
    // Request revision 1
    internal_module_count: u64 = 0,
    internal_modules: ?[*]const *const InternalModule = null,
};

// RSDP

/// The response to the RSDP request. If the base revision is 1 or higher,
/// the response will contain physical addresses to the RSDP, otherwise
/// the response will contain virtual addresses to the RSDP.
pub const RsdpResponse = extern struct {
    revision: u64,
    address: u64,
};

pub const RsdpRequest = extern struct {
    id: [4]u64 = id(0xc5e77b6b397e7b43, 0x27637845accdcf3c),
    revision: u64 = 0,
    response: ?*RsdpResponse = null,
};

// SMBIOS

/// The response to the SMBIOS request. If the base revision is 3 or higher,
/// the response will contain physical addresses to the SMBIOS entries, otherwise
/// the response will contain virtual addresses to the SMBIOS entries.
pub const SmBiosResponse = extern struct {
    revision: u64,
    entry_32: u64,
    entry_64: u64,
};

pub const SmBiosRequest = extern struct {
    id: [4]u64 = id(0x9e9046f11e095391, 0xaa4a520fefbde5ee),
    revision: u64 = 0,
    response: ?*SmBiosResponse = null,
};

// EFI system table

/// The response to the EFI system table request. If the base revision is 3
/// or higher, the response will contain a physical address to the system table,
/// otherwise the response will contain a virtual address to the system table.
pub const EfiSystemTableResponse = extern struct {
    revision: u64,
    address: u64,
};

pub const EfiSystemTableRequest = extern struct {
    id: [4]u64 = id(0x5ceba5163eaaf6d6, 0x0a6981610cf65fcc),
    revision: u64 = 0,
    response: ?*EfiSystemTableResponse = null,
};

// EFI memory map

pub const EfiMemoryMapResponse = extern struct {
    revision: u64,
    memmap: *anyopaque,
    memmap_size: u64,
    desc_size: u64,
    desc_version: u64,
};

pub const EfiMemoryMapRequest = extern struct {
    id: [4]u64 = id(0x7df62a431d6872d5, 0xa4fcdfb3e57306c8),
    revision: u64 = 0,
    response: ?*EfiMemoryMapResponse = null,
};

// Date at boot (formerly Boot time)

pub const DateAtBootResponse = extern struct {
    revision: u64,
    timestamp: i64,
};

pub const DateAtBootRequest = extern struct {
    id: [4]u64 = id(0x502746e184c088aa, 0xfbc5ec83e6327893),
    revision: u64 = 0,
    response: ?*DateAtBootResponse = null,
};

// Executable address (formerly Kernel address)

pub const ExecutableAddressResponse = extern struct {
    revision: u64,
    physical_base: u64,
    virtual_base: u64,
};

pub const ExecutableAddressRequest = extern struct {
    id: [4]u64 = id(0x71ba76863cc55f63, 0xb2644a48c516a487),
    revision: u64 = 0,
    response: ?*ExecutableAddressResponse = null,
};

// Device Tree Blob

pub const DtbResponse = extern struct {
    revision: u64,
    dtb_ptr: *anyopaque,
};

pub const DtbRequest = extern struct {
    id: [4]u64 = id(0xb40ddb48fb54bac7, 0x545081493f81ffb7),
    revision: u64 = 0,
    response: ?*DtbResponse = null,
};

// RISC-V Boot Hart ID

pub const RiscvBootHartIdResponse = extern struct {
    revision: u64,
    bsp_hartid: u64,
};

pub const RiscvBootHartIdRequest = extern struct {
    id: [4]u64 = id(0x1369359f025525f9, 0x2ff2a56178391bb6),
    revision: u64 = 0,
    response: ?*RiscvBootHartIdResponse = null,
};

comptime {
    std.testing.refAllDeclsRecursive(@This());
}
