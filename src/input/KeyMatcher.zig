const KeyMatcher = @This();

const vaxis = @import("vaxis");
const std = @import("std");
const Set = @import("Binding.zig").Set;

const Action = @import("../corepkg.zig").actions.Action;

root: *const Set,
current: *const Set,

pub fn init(root: *const Set) KeyMatcher {
    return .{
        .root = root,
        .current = root,
    };
}

pub fn reset(self: *KeyMatcher) void {
    self.current = self.root;
}

pub const Result = union(enum) {
    no_match,
    pending,
    action: std.meta.Tag(Action),
};

pub fn feedKey(self: *KeyMatcher, key: vaxis.Key) Result {
    const value = self.findMatch(key) orelse {
        self.reset();
        return .no_match;
    };

    switch (value) {
        .leader => |child| {
            self.current = child;
            return .pending;
        },
        .leaf_node => |action_tag| {
            self.reset();
            return .{ .action = action_tag };
        }
    }
}

pub fn findMatch(self: *KeyMatcher, key: vaxis.Key) ?Set.Value {
    const triggers = self.current.tree.keys();
    const values = self.current.tree.values();

    for (triggers, values) |trigger, value| {
        if (key.matchExact(trigger.codepoint, trigger.modifiers)) {
            return value;
        }
    }

    return null;
}
