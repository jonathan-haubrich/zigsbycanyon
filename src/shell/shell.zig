const std = @import("std");
const _client = @import("../client/client.zig");

pub const RemoteShell = struct {
    const Self = @This();

    prompt: []const u8,
    client: _client.Client,

    pub fn init(client: _client.Client) RemoteShell {
        return RemoteShell{
            .prompt = "> ",
            .client = client,
        };
    }

    pub fn prompt_loop(self: *Self) !void {
        var buffer = std.ArrayList(u8).init(self.client.allocator);
        while (!std.mem.eql(u8, buffer.items, "exit")) {
            buffer.clearRetainingCapacity();
            try self.client.stream.reader().streamUntilDelimiter(buffer.writer(), '\n', null);
            std.debug.print("Read from other side: {s}\n", .{buffer.items});
        }
    }
};
