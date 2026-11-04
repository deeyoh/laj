const std = @import("std");
const vaxis = @import("vaxis");

const laj = @import("laj");
const LajTui = @import("tui/LajTui.zig");

const Event = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const alloc = init.gpa;

    var buffer: [1024]u8 = undefined;
    var tty = try vaxis.Tty.init(io, &buffer);
    defer tty.deinit();

    var vx = try vaxis.init(io, alloc, init.environ_map, .{});
    defer vx.deinit(alloc, tty.writer());

    var event_loop: vaxis.Loop(Event) = .init(io, &tty, &vx);

    try event_loop.start();
    defer event_loop.stop();

    try vx.enterAltScreen(tty.writer());
    defer vx.exitAltScreen(tty.writer()) catch {};

    var tui: LajTui = .{};

    try vx.queryTerminal(tty.writer(), .fromSeconds(1));

    while (true) {
        const event = try event_loop.nextEvent();

        switch (event) {
            .winsize => |ws| {
                try vx.resize(alloc, tty.writer(), ws);
            },
            else => {},
        }

        const win = vx.window();
        win.clear();

        tui.draw(vx.window());
        try vx.render(tty.writer());
    }
}
