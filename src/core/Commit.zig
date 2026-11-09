const Commit = @This();

commit_id: []const u8,
change_id: []const u8,
display_id: []const u8 = "",
parents: []const []const u8,
description: []const u8,
author: Signature,
committer: Signature,
/// The text from JJ's log command. The first entry is
/// the node prefix while the remaining are trailing
/// connectors.
graph_lines: []const []const u8 = &.{},

const Signature = struct {
    name: []const u8,
    email: []const u8,
    timestamp: []const u8,
};

test "parse JJ commit without display-only fields" {
    const std = @import("std");
    const parsed = try std.json.parseFromSlice(Commit, std.testing.allocator,
        \\{"commit_id":"abc","change_id":"xyz","parents":[],"description":"", "author":{"name":"A","email":"a@example.com","timestamp":"2026-01-01T00:00:00Z"},"committer":{"name":"A","email":"a@example.com","timestamp":"2026-01-01T00:00:00Z"}}
    , .{});
    defer parsed.deinit();

    try std.testing.expectEqualStrings("abc", parsed.value.commit_id);
    try std.testing.expectEqualStrings("", parsed.value.display_id);
    try std.testing.expectEqual(@as(usize, 0), parsed.value.graph_lines.len);
}
