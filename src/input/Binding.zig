const Binding = @This();

const std = @import("std");
const vaxis = @import("vaxis");
const corepkg = @import("../corepkg.zig");

trigger: Trigger,
value: Set.Value,

/// Represents a prefix tree of `Binding`.
pub const Set = struct {
    const Map = std.array_hash_map.Custom(
        Trigger,
        Value,
        Context(Trigger),
        true,
    );

    /// A value can be a leader key prefix, which would
    /// point to another set. Else, the value represents
    /// a leaf node and is the final node within the trie
    /// system, resulting in a valid action.
    pub const Value = union(enum) {
        leaf_node: std.meta.Tag(corepkg.actions.Action),
        leader: *Set,
    };

    tree: Map = .empty,

    pub fn deinit(self: *Set, alloc: std.mem.Allocator) void {
        for (self.tree.values()) |value| {
            switch (value) {
                .leaf_node => {},
                .leader => |child| {
                    child.deinit(alloc);
                    alloc.destroy(child);
                },
            }
        }
        self.tree.deinit(alloc);
        self.* = .{};
    }

    /// This defines how the hash map gets the hash key and checks for equality.
    fn Context(comptime KeyType: type) type {
        return struct {
            pub fn hash(ctx: @This(), k: KeyType) u32 {
                _ = ctx;
                return @truncate(k.hash());
            }

            pub fn eql(
                ctx: @This(),
                a: KeyType,
                b: KeyType,
                b_index: usize,
            ) bool {
                _ = ctx;
                _ = b_index;
                return a.bindingEql(b);
            }
        };
    }

    /// Parses config keybind input value and inserts into the bind prefix tree
    pub fn parseAndPut(
        self: *Set,
        alloc: std.mem.Allocator,
        keybind_value: []const u8,
    ) !void {
        const separator = std.mem.findScalar(u8, keybind_value, '=') orelse return error.InvalidConfigSyntax;

        const trigger_text = std.mem.trim(u8, keybind_value[0..separator], " \t\r\n");
        const action_text = std.mem.trim(u8, keybind_value[separator + 1 ..], " \t\r\n");

        const action_tag = try corepkg.actions.parse(action_text);

        const trigger_sequence = try parseSequence(alloc, trigger_text);
        defer alloc.free(trigger_sequence);

        try self.putSequence(alloc, trigger_sequence, action_tag);
    }

    /// Inserts a trigger sequence into the prefix tree with its corresponding action
    /// as value.
    fn putSequence(
        self: *Set,
        alloc: std.mem.Allocator,
        sequence: []const Trigger,
        action: std.meta.Tag(corepkg.actions.Action),
    ) !void {
        if (sequence.len == 0) return error.EmptySequence;

        const trigger = sequence[0];
        const is_final = sequence.len == 1;

        if (self.tree.getPtr(trigger)) |existing| {
            switch (existing.*) {
                .leaf_node => {
                    // A trigger sequence cannot be both a leader and a leaf node
                    if (!is_final) return error.BindingPrefixConflict;

                    existing.* = .{ .leaf_node = action };
                },
                .leader => |child_set| {
                    // This sequence operates as a leader key already. So it
                    // cannot be inserted into the tree as a final trigger sequence
                    if (is_final) return error.BindingPrefixConflict;
                    try child_set.putSequence(alloc, sequence[1..], action);
                },
            }
            return;
        }

        if (is_final) {
            try self.tree.put(alloc, trigger, .{ .leaf_node = action });
        } else {
            const child = try alloc.create(Set);
            child.* = .{};
            errdefer {
                child.deinit(alloc);
                alloc.destroy(child);
            }

            try child.putSequence(alloc, sequence[1..], action);
            try self.tree.put(alloc, trigger, .{ .leader = child });
        }
    }

    /// Parses each '>'-separated trigger step in one key press, such as "ctrl+s>p"
    fn parseSequence(alloc: std.mem.Allocator, trigger_text: []const u8) ![]Trigger {
        var sequence: std.ArrayList(Trigger) = .empty;
        errdefer sequence.deinit(alloc);

        var steps = std.mem.splitScalar(u8, trigger_text, '>');

        while (steps.next()) |sequence_step| {
            const trigger = try Trigger.parse(sequence_step);
            try sequence.append(alloc, trigger);
        }

        return try sequence.toOwnedSlice(alloc);
    }
};

/// Represents one key press, including its modifiers, such as "ctrl+j".
/// Sequences are represented by paths through nested `Set`s.
pub const Trigger = struct {
    codepoint: u21,
    modifiers: vaxis.Key.Modifiers = .{},

    pub fn hash(self: Trigger) u64 {
        var hasher = std.hash.Wyhash.init(0);

        std.hash.autoHash(&hasher, self.codepoint);
        const modifiers: u8 = @bitCast(self.modifiers);
        std.hash.autoHash(&hasher, modifiers);

        return hasher.final();
    }

    pub fn bindingEql(self: Trigger, other: Trigger) bool {
        return self.codepoint == other.codepoint and self.modifiers.eql(other.modifiers);
    }

    /// Parses one trigger step in a binding, such as "j", "tab", or "ctrl+shift+j".
    /// It does not parse an entire sequence.
    pub fn parse(sequence_step: []const u8) !Trigger {
        const trimmed = std.mem.trim(u8, sequence_step, " \t\r\n");

        if (trimmed.len == 0) return error.EmptyTrigger;

        var parts = std.mem.splitScalar(u8, trimmed, '+');
        var part = parts.next() orelse return error.EmptyTrigger;

        var modifiers: vaxis.Key.Modifiers = .{};

        while (parts.next()) |next| {
            const modifier = std.mem.trim(u8, part, " \t");

            if (std.mem.eql(u8, modifier, "ctrl")) {
                if (modifiers.ctrl) return error.DuplicateModifier;
                modifiers.ctrl = true;
            } else if (std.mem.eql(u8, modifier, "alt")) {
                if (modifiers.alt) return error.DuplicateModifier;
                modifiers.alt = true;
            } else if (std.mem.eql(u8, modifier, "shift")) {
                if (modifiers.shift) return error.DuplicateModifier;
                modifiers.shift = true;
            } else {
                return error.UnknownModifier;
            }

            part = next;
        }

        const name = std.mem.trim(u8, part, " \t");
        if (name.len == 0) return error.EmptyKey;

        return .{
            .codepoint = try parseCodepoint(name),
            .modifiers = modifiers,
        };
    }

    /// Parses a codepoint text value into a vaxis `Codepoint`, which
    /// is represented as a `u21`.
    fn parseCodepoint(codepoint_name: []const u8) !u21 {
        const NamedKey = struct {
            name: []const u8,
            codepoint: u21,
        };

        const named_keys = [_]NamedKey{
            .{ .name = "tab", .codepoint = vaxis.Key.tab },
            .{ .name = "enter", .codepoint = vaxis.Key.enter },
            .{ .name = "backspace", .codepoint = vaxis.Key.backspace },
            .{ .name = "escape", .codepoint = vaxis.Key.escape },
            .{ .name = "up", .codepoint = vaxis.Key.up },
            .{ .name = "down", .codepoint = vaxis.Key.down },
            .{ .name = "left", .codepoint = vaxis.Key.left },
            .{ .name = "right", .codepoint = vaxis.Key.right },
            .{ .name = "space", .codepoint = vaxis.Key.space },
            .{ .name = "plus", .codepoint = '+' },
            .{ .name = "greater", .codepoint = '>' },
            .{ .name = "equal", .codepoint = '=' },
        };

        for (named_keys) |named| {
            if (std.mem.eql(u8, codepoint_name, named.name)) {
                return named.codepoint;
            }
        }

        if (codepoint_name.len == 0) return error.EmptyKey;

        const length = std.unicode.utf8ByteSequenceLength(codepoint_name[0]) catch
            return error.InvalidKey;

        if (codepoint_name.len != length) return error.UnknownKey;

        return std.unicode.utf8Decode(codepoint_name) catch
            return error.InvalidKey;
    }
};

test "trigger parsing, hashing, and equality" {
    const trigger = try Trigger.parse(" ctrl+shift+j ");
    try std.testing.expect(trigger.modifiers.ctrl);
    try std.testing.expect(trigger.modifiers.shift);
    try std.testing.expectEqual(@as(u21, 'j'), trigger.codepoint);
    const same = try Trigger.parse("shift+ctrl+j");
    try std.testing.expect(trigger.bindingEql(same));
    try std.testing.expectEqual(trigger.hash(), same.hash());
    try std.testing.expect(!trigger.bindingEql(try Trigger.parse("j")));
    try std.testing.expectEqual(@as(u21, '='), (try Trigger.parse("equal")).codepoint);
    try std.testing.expectEqual(@as(u21, 'é'), (try Trigger.parse("é")).codepoint);
    try std.testing.expectError(error.DuplicateModifier, Trigger.parse("ctrl+ctrl+j"));
    try std.testing.expectError(error.UnknownModifier, Trigger.parse("unknown+j"));
    try std.testing.expectError(error.EmptyKey, Trigger.parse("ctrl+"));
}

test "binding trie inserts, replaces, and rejects prefix conflicts" {
    const alloc = std.testing.allocator;
    var set: Set = .{};
    defer set.deinit(alloc);

    try set.parseAndPut(alloc, " ctrl+s > p = cycle_pane_focus\r\n");
    try set.parseAndPut(alloc, "ctrl+s>j=cycle_pane_focus");
    try set.parseAndPut(alloc, "ctrl+s>p=cycle_pane_focus");

    const child = set.tree.get(try Trigger.parse("ctrl+s")).?.leader;
    try std.testing.expectEqual(@as(usize, 2), child.tree.count());
    try std.testing.expectEqual(
        std.meta.Tag(corepkg.actions.Action).cycle_pane_focus,
        child.tree.get(try Trigger.parse("p")).?.leaf_node,
    );
    try std.testing.expectError(error.BindingPrefixConflict, set.parseAndPut(alloc, "ctrl+s=cycle_pane_focus"));
    try std.testing.expectError(error.BindingPrefixConflict, set.parseAndPut(alloc, "ctrl+s>p>x=cycle_pane_focus"));
    try std.testing.expectError(error.InvalidAction, set.parseAndPut(alloc, "x=unknown"));
    try std.testing.expectError(error.InvalidConfigSyntax, set.parseAndPut(alloc, "x"));
    try std.testing.expectError(error.EmptyTrigger, set.parseAndPut(alloc, "x>=cycle_pane_focus"));
}

fn testBindingAllocationFailures(alloc: std.mem.Allocator) !void {
    var set: Set = .{};
    defer set.deinit(alloc);
    try set.parseAndPut(alloc, "ctrl+s>p=cycle_pane_focus");
}

test "binding insertion cleans up on allocation failure" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, testBindingAllocationFailures, .{});
}
