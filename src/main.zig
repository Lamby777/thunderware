const std = @import("std");
const os = std.os;
const mem = std.mem;
const rand = std.rand;
const prng = rand.ChaCha;
const crypto = std.crypto;

const algo = crypto.aead.chacha_poly.XChaCha20Poly1305;

pub fn main() anyerror!void {
    const folderPath = "./path/to/folder"; // Specify the folder path here
    const keyFilePath = "./path/to/key.txt"; // Specify the key file path here

    // Generate a random key
    prng.init(std.time.milliTimestamp());
    var key: [32]u8 = undefined;
    prng.int.fill(key[0..]);

    // Write the key to the key file
    const keyFile = try os.create(keyFilePath);
    defer keyFile.close();
    try keyFile.writeAll(key[0..]);

    // Encrypt files in the folder
    const dir = try os.openDir(folderPath);
    defer dir.close();

    while (true) |entry| {
        const entryName = entry.name() orelse break;
        if (entry.isDir()) continue;

        const filePath = try std.build.pathAppend(null, folderPath, entryName);
        const encryptedFilePath = try std.build.pathAppend(null, folderPath, entryName ++ ".encrypted");

        const file = try os.openFile(filePath, .{ .read = true });
        defer file.close();

        const encryptedFile = try os.create(encryptedFilePath);
        defer encryptedFile.close();

        var buffer: [4096]u8 = undefined;
        while (true) |readResult| {
            _ = readResult;
            const bytesRead = try file.read(buffer[0..]);
            if (bytesRead == 0) break;

            const encryptedBytes = encrypt(buffer[0..bytesRead], key);
            try encryptedFile.writeAll(encryptedBytes[0..]);
        }
    }
}

fn encrypt(data: []const u8, key: []const u8) []u8 {
    const length = data.len;
    var encrypted: [length]u8 = undefined;

    for (encrypted, data, key) |enc, dat, k| {
        enc.* = dat ^ k;
    }

    return encrypted;
}
