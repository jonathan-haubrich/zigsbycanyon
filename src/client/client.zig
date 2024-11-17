const std = @import("std");

pub const Client = struct {
    pub const State = enum { Disconnected, Connected };
    addr: std.net.Address,
    state: State,
    stream: std.net.Stream,
    allocator: std.mem.Allocator,

    pub fn init(ip: []const u8, port: u16, allocator: std.mem.Allocator) !Client {
        const addr = try std.net.Address.parseIp(ip, port);

        return Client{
            .addr = addr,
            .state = State.Disconnected,
            .stream = undefined,
            .allocator = allocator,
        };
    }

    pub fn connect(self: *Client) !void {
        self.stream = try std.net.tcpConnectToAddress(self.addr);

        self.state = State.Connected;
    }

    pub fn send(self: Client, data: []const u8) !void {
        try self.stream.writeAll(data);
    }

    pub fn recv(self: Client, size: u32) ![]u8 {
        const buffer = try self.allocator.alloc(u8, size);

        _ = try self.stream.read(buffer);

        return buffer;
    }
};
