const std = @import("std");
const inputpkg = @import("../inputpkg.zig");

const file_load = @import("file_load.zig");

pub const Keybinds = struct {
    set: inputpkg.Binding.Set = .{},
};


pub fn load(
    io: std.Io,
    alloc: std.mem.Allocator,
    environ_map: *std.process.Environ.Map,
) !void {
    const config_path = try configPath(alloc, environ_map);
    defer alloc.free(config_path);

    const file = std.Io.Dir.cwd().openFile(io, config_path, .{}) catch |err| switch (err) {
        error.FileNotFound => blk: {
            //create file with defaults
            const cwd = std.Io.Dir.cwd();

            if (std.Io.Dir.path.dirname(config_path)) |parent| {
                try cwd.createDirPath(io, parent);
            }

            const created = try cwd.createFile(io, config_path, .{
                .read = true,
                .exclusive = true,
            });
            errdefer created.close(io);

            var buffer: [4096]u8 = undefined;
            var writer = created.writerStreaming(io, &buffer);

            try writer.interface.writeAll(inputpkg.default_config);
            try writer.interface.flush();

            break :blk created;
        },
        else => return err,
    };
    defer file.close(io);

    //begin reading and parsing (if invalid return error)
    var buffer: [2048]u8 = undefined;
    var reader = file.reader(io, &buffer);

    const contents = try reader.interface.allocRemaining(alloc, .limited(1024 * 1024));

    var line_iterator = file_load.LineIterator.init(contents);

    while (line_iterator.next()) |line| {
        std.log.info("line: {s}\n", .{ line });
    }
}


/// Returns the expected absolute path of the configuration file. If set, it returns
/// the default path using `$XDG_CONFIG_HOME`, else `$HOME`.
fn configPath(
    alloc: std.mem.Allocator,
    environ_map: *std.process.Environ.Map,
) ![]const u8 {
    const config_dir = try file_load.defaultXdgPath(alloc, environ_map);
    defer alloc.free(config_dir);

    return std.Io.Dir.path.join(alloc, &.{ config_dir, "config.laj" });
}
