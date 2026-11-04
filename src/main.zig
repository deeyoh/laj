const std = @import("std");
const vaxis = @import("vaxis");

const laj = @import("laj");
const LajTui = @import("tui/LajTui.zig");

const Commit = @import("core/Commit.zig");
const CommitGraph = @import("tui/commits/Graph.zig");

const Event = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const alloc = init.gpa;

    const result = try std.process.run(alloc, io, .{
        .argv = &.{
            "jj",
            "log",
            "--no-graph",
            "--color",
            "never",
            "-T",
            "json(self) ++ \"\\n\"",
        },
    });
    defer alloc.free(result.stdout);
    defer alloc.free(result.stderr);

    switch (result.term) {
        .exited => |code| {
            if (code != 0) {
                return error.JjCommandFailed;
            }
        },
        else => return error.JjCommandFailed,
    }

    var commits_arena = std.heap.ArenaAllocator.init(alloc);
    defer commits_arena.deinit();

    var commits: std.ArrayList(Commit) = .empty;

    var lines = std.mem.splitScalar(u8, result.stdout, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const parsed_commit = try std.json.parseFromSliceLeaky(
            Commit, 
            commits_arena.allocator(), 
            line, 
            .{ 
                .ignore_unknown_fields = true, 
                .allocate = .alloc_always 
            }
        );

        try commits.append(commits_arena.allocator(), parsed_commit);
    }

    const lanes = [_]CommitGraph.Lane{
        .{ .target = "commit-A" },
        .{},
        .{ .target = "commit-B" },
    };

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

    var tui: LajTui = .{
        .commits = commits.items,
    };

    try vx.queryTerminal(tty.writer(), .fromSeconds(1));

    while (true) {
        const event = try event_loop.nextEvent();

        switch (event) {
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true })) {
                    break;
                } else if (key.matches(vaxis.Key.tab, .{})) {
                    tui.cycleFocus();
                }
            },
            .winsize => |ws| {
                try vx.resize(alloc, tty.writer(), ws);
            },
            // else => {},
        }

        const win = vx.window();
        win.clear();

        tui.draw(vx.window());
        try vx.render(tty.writer());
    }
}
