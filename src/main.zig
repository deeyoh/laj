const std = @import("std");
const vaxis = @import("vaxis");
const builtin = @import("builtin");

const laj = @import("laj");
const LajTui = @import("tui/LajTui.zig");

const App = @import("App.zig");

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

    var app = try App.init(io, alloc, init.environ_map);
    defer app.deinit(alloc);

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
        .commits = app.commits,
    };

    try vx.queryTerminal(tty.writer(), .fromSeconds(1));

    while (true) {
        const event = try event_loop.nextEvent();

        switch (event) {
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true })) {
                    break;
                }

                if (key.matches(vaxis.Key.escape, .{})) {
                    std.log.info("matcher reset\n", .{});
                } else if (!key.isModifier()) {
                    switch (app.key_matcher.feedKey(key)) {
                        .no_match => {
                            std.log.warn("no key match: {}\n", .{ key });
                        },
                        .pending => {
                            std.log.info("leader matched: {}. waiting for next key", .{ key });
                        },
                        .action => |action| {
                            std.log.info("action leaf node matched: {}. executing", .{ key });
                            switch (action) {
                                .cycle_pane_focus => {
                                    tui.cyclePaneFocus();
                                },
                                .motion_up => {
                                    tui.active_view.log.commit_log_pane.prevCommitRow(app.commits.len);
                                },
                                .motion_down => {
                                    tui.active_view.log.commit_log_pane.nextCommitRow(app.commits.len);
                                }
                            }
                        }
                    }
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
