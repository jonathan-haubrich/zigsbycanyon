const std = @import("std");
const shell = @import("../shell/shell.zig");

pub fn exit(self: *shell.RemoteShell, _: std.ArrayList([]const u8)) ![]const u8 {
    self.should_exit = true;

    return undefined;
}
