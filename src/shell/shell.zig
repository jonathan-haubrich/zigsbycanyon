const std = @import("std");
const _client = @import("../client/client.zig");
const command_dir = @import("../command/dir.zig");
const command_exit = @import("../command/exit.zig");

pub const RemoteShell = struct {
    const Self = @This();

    const SupportedCommands = std.StringHashMap(*const fn (*RemoteShell, std.ArrayList([]const u8)) anyerror![]const u8);

    prompt: []const u8,
    client: _client.Client,
    supported_commands: SupportedCommands,
    should_exit: bool,

    pub fn init(client: _client.Client) !RemoteShell {
        var supported_commands = SupportedCommands.init(client.allocator);
        try supported_commands.put("dir", command_dir.dir);
        try supported_commands.put("ls", command_dir.dir);
        try supported_commands.put("exit", command_exit.exit);
        try supported_commands.put("quit", command_exit.exit);

        return RemoteShell{
            .prompt = "> ",
            .client = client,
            .supported_commands = supported_commands,
            .should_exit = false,
        };
    }

    pub fn prompt_loop(self: *Self) !void {
        var buffer = std.ArrayList(u8).init(self.client.allocator);
        while (!self.should_exit) {
            try self.client.stream.writeAll(self.prompt);
            buffer.clearRetainingCapacity();
            try self.client.stream.reader().streamUntilDelimiter(buffer.writer(), '\n', null);
            std.debug.print("Read from other side: {s}\n", .{buffer.items});

            var args = try self.parse(buffer.items);
            std.debug.print("Parsed args: {any}\n", .{args});

            var response: []const u8 = "";
            if (args.items.len == 0) {
                continue;
            }

            const command = args.orderedRemove(0);
            const entry = self.supported_commands.get(command);
            std.debug.print("Entry: {any}\n", .{entry});
            if (entry) |handler| {
                response = try handler(self, args);
            } else {
                var response_buffer = std.ArrayList(u8).init(self.client.allocator);
                try std.fmt.format(response_buffer.writer(), "[ERROR] Invalid command: {s}\n", .{args.items[0]});
                response = response_buffer.items;
            }

            args.deinit();

            try self.client.stream.writeAll(response);
        }
    }

    pub fn parse(self: *Self, cmdline: []const u8) !std.ArrayList([]const u8) {
        var args = std.ArrayList([]const u8).init(self.client.allocator);

        var splits = std.mem.split(u8, cmdline, " ");
        while (splits.next()) |split| {
            try args.append(split);
        }

        return args;
    }
};
