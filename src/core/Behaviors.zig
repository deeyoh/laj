const Behaviors = @This();

const std = @import("std");

log_commits: LogStartup,

/// Determines whether to log all commits within JJ
/// or to use its default behavior. This affects
/// the command that `App` uses to load commits
/// for the entire Laj TUI to use.
const LogStartup = enum { default, all };


pub const Scope = enum { startup };

/// Controls configurable behavior options of the app.
pub const Value = union(enum) {
    log_commits: LogStartup,

    pub fn scope(behavior: Value) Scope {
        return switch (behavior) {
            .log_commits => .startup,
        };
    }
};

/// Parses a given behavior input to check if it is a valid behavior.
/// If so, returns the `Value`.
pub fn parse(behavior_text: []const u8) !Value {
    const separator = std.mem.findScalar(u8, behavior_text, ':') orelse
        return error.InvalidBehaviorSyntax;

    const variant = std.mem.trim(u8, behavior_text[0..separator], " \t");
    const value = std.mem.trim(u8, behavior_text[separator + 1..], " \t");

    const tag = std.meta.stringToEnum(
        std.meta.Tag(Value),
        variant
    ) orelse return error.InvalidBehavior;

    return switch (tag) {
        .log_commits => .{
            .log_commits = std.meta.stringToEnum(LogStartup, value) orelse
                return error.InvalidBehaviorValue,
        },
    };
}

pub fn apply(self: *Behaviors, behavior: Value) void {
    switch (behavior) {
        .log_commits => |value| self.log_commits = value,
    }
}


