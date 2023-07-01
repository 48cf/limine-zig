const std = @import("std");
const builtin = @import("builtin");

inline fn magic(a: u64, b: u64) [4]u64 {
    return .{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, a, b };
}

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
};

pub const File = extern struct {
    revision: u64,
    address: [*]u8,
    size: u64,
    path: [*:0]u8,
    cmdline: [*:0]u8,
    media_type: MediaType,
    unused: u32,
    tftp_ip: u32,
    tftp_port: u32,
    partition_index: u32,
    mbr_disk_id: u32,
    gpt_disk_uuid: Uuid,
    gpt_part_uuid: Uuid,
    part_uuid: Uuid,

    pub inline fn data(self: *@This()) []u8 {
        return self.address[0..self.size];
    }
};

// Boot info

pub const BootloaderInfoResponse = extern struct {
    revision: u64,
    name: [*:0]u8,
    version: [*:0]u8,
};

pub const BootloaderInfoRequest = extern struct {
    id: [4]u64 = magic(0xf55038d8e2a1202f, 0x279426fcf5f59740),
    revision: u64 = 0,
    response: ?*BootloaderInfoResponse = null,
};

// Stack size

pub const StackSizeResponse = extern struct {
    revision: u64,
};

pub const StackSizeRequest = extern struct {
    id: [4]u64 = magic(0x224ef0460a8e8926, 0xe1cb0fc25f46ea3d),
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
    id: [4]u64 = magic(0x48dcf1cb8ad2b852, 0x63984e959a98244b),
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
    memory_model: u8,
    red_mask_size: u8,
    red_mask_shift: u8,
    green_mask_size: u8,
    green_mask_shift: u8,
    blue_mask_size: u8,
    blue_mask_shift: u8,
};

pub const Framebuffer = extern struct {
    address: [*]u8,
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
    unused: [7]u8,
    edid_size: u64,
    edid: ?[*]u8,

    // Response revision 1
    mode_count: u64,
    modes: [*]*VideoMode,

    pub inline fn data(self: *@This()) []u8 {
        return self.address[0 .. self.pitch * self.height];
    }

    pub inline fn edidData(self: *@This()) ?[]u8 {
        if (self.edid) |edid_data| {
            return edid_data[0..self.edid_size];
        }
        return null;
    }

    pub inline fn videoModes(self: *@This()) []*VideoMode {
        return self.modes[0..self.mode_count];
    }
};

pub const FramebufferResponse = extern struct {
    revision: u64,
    framebuffer_count: u64,
    framebuffers_ptr: [*]*Framebuffer,

    pub inline fn framebuffers(self: *@This()) []*Framebuffer {
        return self.framebuffers_ptr[0..self.framebuffer_count];
    }
};

pub const FramebufferRequest = extern struct {
    id: [4]u64 = magic(0x9d5827dcd881dd75, 0xa3148604f6fab11b),
    revision: u64 = 1,
    response: ?*FramebufferResponse = null,
};

// Terminal

pub const Terminal = extern struct {
    columns: u64,
    rows: u64,
    framebuffer: *Framebuffer,
};

pub const OobOutputFlags = enum(u64) {
    ocrnl = 1 << 0,
    ofdel = 1 << 1,
    ofill = 1 << 2,
    olcuc = 1 << 3,
    onlcr = 1 << 4,
    onlret = 1 << 5,
    onocr = 1 << 6,
    opost = 1 << 7,
};

pub const TerminalResponse = extern struct {
    revision: u64,
    terminal_count: u64,
    terminals_ptr: [*]*Terminal,
    write_fn: *const fn (*Terminal, [*]const u8, u64) callconv(.C) void,

    pub inline fn terminals(self: *@This()) []*Terminal {
        return self.terminals_ptr[0..self.terminal_count];
    }

    pub inline fn write(self: *@This(), terminal: ?*Terminal, string: []const u8) void {
        self.write_fn(terminal orelse self.terminals_ptr[0], string.ptr, string.len);
    }

    pub inline fn ctxSize(self: *@This(), terminal: ?*Terminal) u64 {
        var result: u64 = undefined;
        self.write_fn(terminal orelse self.terminals_ptr[0], @as([*]const u8, @ptrCast(&result)), @as(u64, @bitCast(@as(i64, -1))));
        return result;
    }

    pub inline fn ctxSave(self: *@This(), terminal: ?*Terminal, ctx: [*]u8) void {
        self.write_fn(terminal orelse self.terminals_ptr[0], @as([*]const u8, @ptrCast(ctx)), @as(u64, @bitCast(@as(i64, -2))));
    }

    pub inline fn ctxRestore(self: *@This(), terminal: ?*Terminal, ctx: [*]const u8) void {
        self.write_fn(terminal orelse self.terminals_ptr[0], @as([*]const u8, @ptrCast(ctx)), @as(u64, @bitCast(@as(i64, -3))));
    }

    pub inline fn fullRefresh(self: *@This(), terminal: ?*Terminal) void {
        self.write_fn(terminal orelse self.terminals_ptr[0], "", @as(u64, @bitCast(@as(i64, -4))));
    }

    // Response revision 1
    pub inline fn oobOutputGet(self: *@This(), terminal: ?*Terminal) u64 {
        var result: u64 = undefined;
        self.write_fn(terminal orelse self.terminals_ptr[0], @as([*]const u8, @ptrCast(&result)), @as(u64, @bitCast(@as(i64, -10))));
        return result;
    }

    pub inline fn oobOutputSet(self: *@This(), terminal: ?*Terminal, value: u64) void {
        self.write_fn(terminal orelse self.terminals_ptr[0], @as([*]const u8, @ptrCast(&value)), @as(u64, @bitCast(@as(i64, -11))));
    }
};

pub const CallbackType = enum(u64) {
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

pub const TerminalRequest = extern struct {
    id: [4]u64 = magic(0xc8ac59310c2b0844, 0xa68d0c7265d38878),
    revision: u64 = 0,
    response: ?*TerminalResponse = null,
    callback: ?*const fn (*Terminal, CallbackType, u64, u64, u64) callconv(.C) void = null,
};

// Paging mode

const X86PagingMode = enum(u64) {
    four_level = 0,
    five_level = 1,
    default = .four_level,
};

const AArch64PagingMode = enum(u64) {
    four_level = 0,
    five_level = 1,
    default = .four_level,
};

const RiscVPagingMode = enum(u64) {
    sv39 = 0,
    sv48 = 1,
    sv57 = 2,
    default = .sv48,
};

pub const PagingMode = switch (builtin.cpu.arch) {
    .x86, .x86_64 => X86PagingMode,
    .aarch64 => AArch64PagingMode,
    .riscv64 => RiscVPagingMode,
    else => |arch| @compileError("Unsupported architecture: " ++ @tagName(arch)),
};

pub const PagingModeResponse = extern struct {
    revision: u64,
    mode: PagingMode,
    flags: u64,
};

pub const PagingModeRequest = extern struct {
    id: [4]u64 = magic(0x95c1a0edab0944cb, 0xa4e5cb3842f7488a),
    revision: u64 = 0,
    response: ?*PagingModeResponse = null,
    mode: PagingMode,
    flags: u64,
};

// 5-level paging

pub const FiveLevelPagingResponse = extern struct {
    revision: u64,
};

pub const FiveLevelPagingRequest = extern struct {
    id: [4]u64 = magic(0x94469551da9b3192, 0xebe5e86db7382888),
    revision: u64 = 0,
    response: ?*FiveLevelPagingResponse = null,
};

// SMP
const X86SmpInfo = extern struct {
    processor_id: u32,
    lapic_id: u32,
    reserved: u64,
    goto_address: ?*const fn (*@This()) callconv(.C) noreturn,
    extra_argument: u64,
};

const X86SmpFlags = enum(u32) {
    x2apic = 1 << 0,
};

const X86SmpResponse = extern struct {
    revision: u64,
    flags: u32,
    bsp_lapic_id: u32,
    cpu_count: u64,
    cpus_ptr: [*]*X86SmpInfo,

    pub inline fn cpus(self: *@This()) []*X86SmpInfo {
        return self.cpus_ptr[0..self.cpu_count];
    }
};

const AArch64SmpInfo = extern struct {
    processor_id: u32,
    gic_iface_no: u32,
    mpidr: u64,
    reserved: u64,
    goto_address: ?*const fn (*@This()) callconv(.C) noreturn,
    extra_argument: u64,
};

const AArch64SmpFlags = enum(u32) {};

const AArch64SmpResponse = extern struct {
    revision: u64,
    flags: u32,
    bsp_mpidr: u64,
    cpu_count: u64,
    cpus_ptr: [*]*X86SmpInfo,

    pub inline fn cpus(self: *@This()) []*X86SmpInfo {
        return self.cpus_ptr[0..self.cpu_count];
    }
};

const RiscVSmpInfo = extern struct {
    processor_id: u32,
    hart_id: u32,
    reserved: u64,
    goto_address: ?*const fn (*@This()) callconv(.C) noreturn,
    extra_argument: u64,
};

const RiscVSmpFlags = enum(u32) {};

const RiscVSmpResponse = extern struct {
    revision: u64,
    flags: u32,
    bsp_hart_id: u64,
    cpu_count: u64,
    cpus_ptr: [*]*X86SmpInfo,

    pub inline fn cpus(self: *@This()) []*X86SmpInfo {
        return self.cpus_ptr[0..self.cpu_count];
    }
};

pub const SmpInfo = switch (builtin.cpu.arch) {
    .x86, .x86_64 => X86SmpInfo,
    .aarch64 => AArch64SmpInfo,
    .riscv64 => RiscVSmpInfo,
    else => |arch| @compileError("Unsupported architecture: " ++ @tagName(arch)),
};

pub const SmpFlags = switch (builtin.cpu.arch) {
    .x86, .x86_64 => X86SmpFlags,
    .aarch64 => AArch64SmpFlags,
    .riscv64 => RiscVSmpFlags,
    else => |arch| @compileError("Unsupported architecture: " ++ @tagName(arch)),
};

pub const SmpResponse = switch (builtin.cpu.arch) {
    .x86, .x86_64 => X86SmpResponse,
    .aarch64 => AArch64SmpResponse,
    .riscv64 => RiscVSmpResponse,
    else => |arch| @compileError("Unsupported architecture: " ++ @tagName(arch)),
};

pub const SmpRequest = extern struct {
    id: [4]u64 = magic(0x95a67b819a1b857e, 0xa0b61b723b6a73e0),
    revision: u64 = 0,
    response: ?*SmpResponse = null,
    flags: u64 = 0,
};

// Memory map

pub const MemoryMapEntryType = enum(u64) {
    usable = 0,
    reserved = 1,
    acpi_reclaimable = 2,
    acpi_nvs = 3,
    bad_memory = 4,
    bootloader_reclaimable = 5,
    kernel_and_modules = 6,
    framebuffer = 7,
};

pub const MemoryMapEntry = extern struct {
    base: u64,
    length: u64,
    kind: MemoryMapEntryType,
};

pub const MemoryMapResponse = extern struct {
    revision: u64,
    entry_count: u64,
    entries_ptr: [*]*MemoryMapEntry,

    pub inline fn entries(self: *@This()) []*MemoryMapEntry {
        return self.entries_ptr[0..self.entry_count];
    }
};

pub const MemoryMapRequest = extern struct {
    id: [4]u64 = magic(0x67cf3d9d378a806f, 0xe304acdfc50c3c62),
    revision: u64 = 0,
    response: ?*MemoryMapResponse = null,
};

// Entry point

pub const EntryPointResponse = extern struct {
    revision: u64,
};

pub const EntryPointRequest = extern struct {
    id: [4]u64 = magic(0x13d86c035a1cd3e1, 0x2b0caa89d8f3026a),
    revision: u64 = 0,
    response: ?*EntryPointResponse = null,
    entry: ?*const fn () callconv(.C) noreturn = null,
};

// Kernel file

pub const KernelFileResponse = extern struct {
    revision: u64,
    kernel_file: *File,
};

pub const KernelFileRequest = extern struct {
    id: [4]u64 = magic(0xad97e90e83f1ed67, 0x31eb5d1c5ff23b69),
    revision: u64 = 0,
    response: ?*KernelFileResponse = null,
};

// Module

pub const InternalModuleFlags = enum(u64) {
    required = 1 << 0,
};

pub const InternalModule = extern struct {
    path: [*:0]const u8,
    cmdline: [*:0]const u8,
    flags: InternalModuleFlags,
};

pub const ModuleResponse = extern struct {
    revision: u64,
    module_count: u64,
    modules_ptr: [*]*File,

    pub inline fn modules(self: *@This()) []*File {
        return self.modules_ptr[0..self.module_count];
    }
};

pub const ModuleRequest = extern struct {
    id: [4]u64 = magic(0x3e7e279702be32af, 0xca1c4f3bd1280cee),
    revision: u64 = 1,
    response: ?*ModuleResponse = null,

    // Request revision 1
    internal_module_count: u64 = 0,
    internal_modules: ?[*]const *const InternalModule = null,
};

// RSDP

pub const RsdpResponse = extern struct {
    revision: u64,
    address: *anyopaque,
};

pub const RsdpRequest = extern struct {
    id: [4]u64 = magic(0xc5e77b6b397e7b43, 0x27637845accdcf3c),
    revision: u64 = 0,
    response: ?*RsdpResponse = null,
};

// SMBIOS

pub const SmbiosResponse = extern struct {
    revision: u64,
    entry_32: ?*anyopaque,
    entry_64: ?*anyopaque,
};

pub const SmbiosRequest = extern struct {
    id: [4]u64 = magic(0x9e9046f11e095391, 0xaa4a520fefbde5ee),
    revision: u64 = 0,
    response: ?*SmbiosResponse = null,
};

// EFI system table

pub const EfiSystemStableResponse = extern struct {
    revision: u64,
    address: *anyopaque,
};

pub const EfiSystemTableRequest = extern struct {
    id: [4]u64 = magic(0x5ceba5163eaaf6d6, 0x0a6981610cf65fcc),
    revision: u64 = 0,
    response: ?*EfiSystemStableResponse = null,
};

// Boot time

pub const BootTimeResponse = extern struct {
    revision: u64,
    boot_time: i64,
};

pub const BootTimeRequest = extern struct {
    id: [4]u64 = magic(0x502746e184c088aa, 0xfbc5ec83e6327893),
    revision: u64 = 0,
    response: ?*BootTimeResponse = null,
};

// Kernel address

pub const KernelAddressResponse = extern struct {
    revision: u64,
    physical_base: u64,
    virtual_base: u64,
};

pub const KernelAddressRequest = extern struct {
    id: [4]u64 = magic(0x71ba76863cc55f63, 0xb2644a48c516a487),
    revision: u64 = 0,
    response: ?*KernelAddressResponse = null,
};

// Device tree blob

pub const DeviceTreeBlobResponse = extern struct {
    revision: u64,
    dtb: ?*anyopaque,
};

pub const DeviceTreeBlobRequest = extern struct {
    id: [4]u64 = magic(0xb40ddb48fb54bac7, 0x545081493f81ffb7),
    revision: u64 = 0,
    response: ?*DeviceTreeBlobResponse = null,
};
