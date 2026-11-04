const std = @import("std");
const Io = std.Io;

const laj = @import("laj");

const LajTui = @import("tui/LajTui.zig");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const io = init.io;
}
