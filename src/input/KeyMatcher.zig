const KeyMatcher = @This();

const vaxis = @import("vaxis");
const std = @import("std");
const Set = @import("Binding.zig").Set;

const Action = @import("../corepkg.zig").actions.Action;

current: ?*const Set = null,

pub const Result = union(enum) {
    no_match,
    pending,
    action: std.meta.Tag(Action),
};

pub fn reset(self: *KeyMatcher) void {
    self.current = null;
}

pub fn feedKey(self: *KeyMatcher, root: *const Set, key: vaxis.Key) Result {
    const current = self.current orelse root;

    const value = findMatch(current, key) orelse {
        self.reset();
        return .no_match;
    };

    switch (value) {
        .leader => |child_set| {
            self.current  = child_set;
            return .pending;
        },
        .leaf_node => |action_tag| {
            self.reset();
            return .{ .action = action_tag };
        },
    }
}

pub fn findMatch(current: *const Set, key: vaxis.Key) ?Set.Value {
    const triggers = current.tree.keys();
    const values = current.tree.values();

    for (triggers, values) |trigger, value| {
        if (key.matchExact(trigger.codepoint, trigger.modifiers)) {
            return value;
        }
    }

    return null;
}
