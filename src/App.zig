const App = @This();

const std = @import("std");
const Config = @import("config/Config.zig");
const KeyMatcher = @import("inputpkg.zig").KeyMatcher;
const Commit = @import("corepkg.zig").Commit;

pub const GlobalState = struct {
    config: Config,
};

state: GlobalState,
commits_arena: std.heap.ArenaAllocator,
commits: []const Commit,
key_matcher: KeyMatcher = .{},

pub fn init(io: std.Io, alloc: std.mem.Allocator, environ_map: *std.process.Environ.Map) !App {
    var config: Config = .{};
    errdefer config.bindings.deinit(alloc);
    try config.load(io, alloc, environ_map);

    var commits_arena = std.heap.ArenaAllocator.init(alloc);
    errdefer commits_arena.deinit();

    const commits = try loadCommits(alloc, io, &commits_arena);

    return .{
        .state = .{
            .config = config,
        },
        .commits_arena = commits_arena,
        .commits = commits,
    };
}

fn loadCommits(alloc: std.mem.Allocator, io: std.Io, commits_arena: *std.heap.ArenaAllocator) ![]const Commit {
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

    var commits: std.ArrayList(Commit) = .empty;

    var lines = std.mem.splitScalar(u8, result.stdout, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const separator = std.mem.findScalar(u8, line, '\t') orelse
            return error.InvalidCommitRecord;

        const json_text = line[0..separator];
        const display_id = line[separator + 1..];

        // parseFromSliceLeaky used due to using arena allocator
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

    std.log.info("[{d}] commits parsed", .{ commits.items.len });

    return commits.items;
}

pub fn deinit(self: *App, alloc: std.mem.Allocator) void {
    self.state.config.bindings.deinit(alloc);
    self.commits_arena.deinit();
}
