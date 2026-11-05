const Logger = @This();

const std = @import("std");
const Dir = std.Io.Dir;

const State = struct {
    io: std.Io,
    file: std.Io.File,
};

var state: ?State = null;
var mutex: std.Io.Mutex = .init;

pub fn init(
    io: std.Io,
    environ_map: *std.process.Environ.Map,
    allocator: std.mem.Allocator,
) !void {
    const state_home = environ_map.get("XDG_STATE_HOME");

    const state_dir = if (state_home) |path| blk: {
        if (path.len > 0 and Dir.path.isAbsolute(path)) {
            break :blk try allocator.dupe(u8, path);
        }
        const home = environ_map.get("HOME") orelse return error.HomeNotSet;
        break :blk try Dir.path.join(allocator, &.{ home, ".local", "state" });
    } else blk: {
        const home = environ_map.get("HOME") orelse return error.HomeNotSet;
        break :blk try Dir.path.join(allocator, &.{ home, ".local", "state" });
    };
    defer allocator.free(state_dir);

    const log_dir = try Dir.path.join(allocator, &.{ state_dir, "laj" });
    defer allocator.free(log_dir);

    try std.Io.Dir.cwd().createDirPath(io, log_dir);

    const log_path = try Dir.path.join(allocator, &.{ log_dir, "laj.log" });
    defer allocator.free(log_path);

    const file = try std.Io.Dir.cwd().createFile(io, log_path, .{ .truncate = true });

    state = .{ .io = io, .file = file };
}

pub fn deinit() void {
    if (state) |s| {
        s.file.close(s.io);
        state = null;
    }
}

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    const s = state orelse {
        std.log.defaultLog(level, scope, format, args);
        return;
    };

    mutex.lockUncancelable(s.io);
    defer mutex.unlock(s.io);

    // Unix timestamps give the time of day in UTC.
    const timestamp = std.Io.Clock.real.now(s.io);
    const seconds: u64 = @intCast(@mod(timestamp.toSeconds(), 24 * 60 * 60));
    const hours = @divTrunc(seconds, 3600);
    const minutes = @divTrunc(@mod(seconds, 3600), 60);
    const secs = @mod(seconds, 60);

    var buffer: [4096]u8 = undefined;
    var writer = s.file.writerStreaming(s.io, &buffer);

    writer.interface.print(
        "[{d:0>2}:{d:0>2}:{d:0>2}] [" ++ level.asText() ++ "] (" ++ @tagName(scope) ++ ") " ++ format ++ "\n",
        .{ hours, minutes, secs } ++ args,
    ) catch return;

    writer.interface.flush() catch {};
}
