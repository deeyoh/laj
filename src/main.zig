const std = @import("std");
const vaxis = @import("vaxis");
const builtin = @import("builtin");

const laj = @import("laj");
const LajTui = @import("tui/LajTui.zig");
const Config = @import("config/Config.zig");

const Logger = @import("Logger.zig");
const Commit = @import("core/Commit.zig");
const CommitGraph = @import("tui/commits/Graph.zig");

const Event = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
};

pub const std_options: std.Options = .{
    .logFn = Logger.logFn,
    .log_level = .debug
};


pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const alloc = init.gpa;

    try Logger.init(io, init.environ_map, alloc);
    defer Logger.deinit();

    var config: Config = .{};
    defer config.bindings.deinit(alloc);
    try config.load(io, alloc, init.environ_map);

    const result = try std.process.run(alloc, io, .{
        .argv = &.{
            "jj",
            "log",
            "-r",
            "all()",
            "--no-graph",
            "--color",
            "never",
            "-T",
            "json(self) ++ \"\\t\" ++ change_id.shortest(8) ++ \"\\n\"",
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

        const separator = std.mem.findScalar(u8, line, '\t') orelse
            return error.InvalidCommitRecord;

        const json_text = line[0..separator];
        const display_id = line[separator + 1..];

        var parsed_commit = try std.json.parseFromSliceLeaky(
            Commit, 
            commits_arena.allocator(), 
            json_text, 
            .{ 
                .ignore_unknown_fields = true, 
                .allocate = .alloc_always 
            }
        );

        parsed_commit.display_id = try commits_arena.allocator().dupe(u8, display_id);
        try commits.append(commits_arena.allocator(), parsed_commit);
    }

    std.log.info("commits parsed: {d}\n", .{ commits.items.len });

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
                }
                // } else if (key.matches(vaxis.Key.tab, .{})) {
                //     Action.performTuiAction(&tui, .{
                //         .cycle_pane_focus = .left_pane,
                //     });
                // }
                // } else if (key.matches(vaxis.Key.tab, .{})) {
                //     tui.cyclePaneFocus();
                // }
                //HANDLE PANE SPECIFIC ACTIONS

                // } else if (tui. == .commits) {
                //     if (key.matches('j', .{}) or key.matches(vaxis.Key.down, .{})) {
                //         tui.commits_pane.nextCommitRow(tui.commits.len);
                //     } else if (key.matches('k', .{}) or key.matches(vaxis.Key.up, .{})) {
                //         tui.commits_pane.prevCommitRow(tui.commits.len);
                //     } else if (key.matches('G', .{})) {
                //         tui.commits_pane.lastRow(tui.commits.len);
                //     }
                //
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
