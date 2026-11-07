const std = @import("std");
const Entry = @import("../inputpkg.zig").Entry;

// Returns the absolute path of $XDG_CONFIG_HOME. If
// the variable is not set it defaults to $HOME/.config
pub fn defaultXdgPath(
    alloc: std.mem.Allocator,
    environ_map: *std.process.Environ.Map,
) ![]const u8 {
    if (environ_map.get("XDG_CONFIG_HOME")) |xdg_config_home| {
        if (xdg_config_home.len > 0 and std.Io.Dir.path.isAbsolute(xdg_config_home)) {
            return std.Io.Dir.path.join(alloc, &.{ xdg_config_home, "laj" });
        }
    }

    const home = environ_map.get("HOME") orelse return error.HomeNotSet;

    if (home.len == 0 or !std.Io.Dir.path.isAbsolute(home)) {
        return error.InvalidHome;
    }

    return std.Io.Dir.path.join(alloc, &.{ home, ".config", "laj" });
}

/// Creates a line iterator the the entire file's contents.
pub const LineIterator = struct {
    // lines: std.mem.splitScalar(u8, .scalar),
    lines: std.mem.SplitIterator(u8, .scalar),

    pub fn init(file_content: []const u8) LineIterator {
        const lines = std.mem.splitScalar(u8, file_content, '\n');

        return .{
            .lines = lines,
        };
    }

    pub fn next(self: *LineIterator) ?[]const u8 {
        return self.lines.next();
    }
};
