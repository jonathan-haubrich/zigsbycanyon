const std = @import("std");
const shell = @import("../shell/shell.zig");

pub fn dir(self: *shell.RemoteShell, args: std.ArrayList([]const u8)) ![]const u8 {
    var entries = std.ArrayList(u8).init(self.client.allocator);

    if (args.items.len < 1) {
        _ = try entries.writer().write("[ERROR:dir] Usage: (ls|dir) <path>\n");
        return entries.items;
    }

    const path = args.items[0];

    const current = std.fs.cwd();
    var target_buffer: [std.fs.max_path_bytes]u8 = undefined;
    const target = current.realpath(path, &target_buffer) catch |err| {
        try std.fmt.format(entries.writer(), "[ERROR:dir] realpath failed: {any}\n", .{err});
        return entries.items;
    };

    std.debug.print("Attempting to read entries from: {s}\n", .{target});

    const root = std.fs.openDirAbsolute(target, std.fs.Dir.OpenDirOptions{ .iterate = true }) catch |err| {
        try std.fmt.format(entries.writer(), "[ERROR:dir] Could not open directory: {any}\n", .{err});
        return entries.items;
    };

    std.debug.print("Absolute dir: {any}\n", .{root});

    try entries.appendSlice(target);
    try entries.append('\n');
    var iterator = root.iterate();
    while (iterator.next()) |entry| {
        std.debug.print("Found entry: {any}\n", .{entry});
        if (entry) |e| {
            const file_stat = root.statFile(e.name) catch |err| {
                std.debug.print("statFile failed: {any}\n", .{err});
                if (err == std.fs.File.OpenError.IsDir) {
                    try entries.appendSlice("<DIR> ");
                    try entries.appendSlice(e.name);
                    try entries.append('\n');
                }
                continue;
            };
            switch (file_stat.kind) {
                std.fs.File.Kind.directory => {
                    try entries.appendSlice("<DIR> ");
                    continue;
                },
                std.fs.File.Kind.sym_link => {
                    try entries.appendSlice("<JUNCTION> ");
                    continue;
                },
                else => {
                    try std.fmt.format(entries.writer(), "{} ", .{std.fmt.fmtIntSizeDec(file_stat.size)});
                    try std.fmt.format(entries.writer(), "{d}|{d}|{d} ", .{ file_stat.atime, file_stat.mode, file_stat.ctime });
                },
            }

            try entries.appendSlice(e.name);
            try entries.append('\n');
        } else {
            break;
        }
    } else |err| {
        entries.clearRetainingCapacity();
        try std.fmt.format(entries.writer(), "[ERROR:dir] Could not iterate directory entries: {any}\n", .{err});
    }

    return entries.items;
}
