const std = @import("std");

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
