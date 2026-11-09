const App = @This();

const std = @import("std");
const Config = @import("config/Config.zig");
const KeyMatcher = @import("inputpkg.zig").KeyMatcher;
const Commit = @import("corepkg.zig").Commit;

// Signifies a new commit record. Lines without `0x1e` are graph lines
// belonging to the current commit record.
const RECORD_SEPARATOR = "\\x1e";

const FIELD_SEPARATOR = "\\t";
const RECORD_END = "\\n\\n";

const LOG_TEMPLATE = 
    "\"" ++ RECORD_SEPARATOR ++ "\"" ++
    " ++ json(self) ++ " ++
    "\"" ++ FIELD_SEPARATOR ++ "\"" ++
    " ++ change_id.shortest(8) ++ " ++
    "\"" ++ RECORD_END ++ "\"";

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
            "--no-pager",
            "--color",
            "never",
            "-T",
            LOG_TEMPLATE,
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
    var graph_lines: std.ArrayList([]const u8) = .empty;

    var lines = std.mem.splitScalar(u8, result.stdout, '\n');

    while (lines.next()) |line| {
        if (line.len == 0 and lines.peek() == null) break;

        // no commit record, process as commit line
        const marker = std.mem.findScalar(u8, line, 0x1e) orelse {
            if (commits.items.len == 0) return error.InvalidCommitRecord;

            try graph_lines.append(commits_arena.allocator(), try commits_arena.allocator().dupe(u8, line));
            continue;
        };

        // we found a new commit, finalize previous
        if (commits.items.len > 0) {
            commits.items[commits.items.len - 1].graph_lines = 
                try graph_lines.toOwnedSlice(commits_arena.allocator());
        }

        const record = line[marker + 1..];

        const separator = std.mem.findScalar(u8, record, '\t') orelse
            return error.InvalidCommitRecord;

        var commit = try std.json.parseFromSliceLeaky(
            Commit,
            commits_arena.allocator(),
            record[0..separator],
            .{
                .ignore_unknown_fields = true,
                .allocate = .alloc_always,
            },
        );

        commit.display_id = try commits_arena.allocator().dupe(u8, record[separator + 1..]);
        commit.graph_lines = &.{};

        try commits.append(commits_arena.allocator(), commit);
        try graph_lines.append(commits_arena.allocator(), try commits_arena.allocator().dupe(u8, line[0..marker]));

        std.log.info("line: {s}\n", .{ line });
    }

    // finalize last commit since never encounters record separator
    if (commits.items.len > 0) {
        commits.items[commits.items.len - 1].graph_lines =
            try graph_lines.toOwnedSlice(commits_arena.allocator());
    }

    return commits.items;
}

pub fn deinit(self: *App, alloc: std.mem.Allocator) void {
    self.state.config.bindings.deinit(alloc);
    self.commits_arena.deinit();
}
