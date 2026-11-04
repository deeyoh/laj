const Graph = @This();

const std = @import("std");
const Commit = @import("../../core/Commit.zig");

pub fn build(
    allocator: std.mem.Allocator,
    commits: []const Commit,
) !void {
    var lanes: std.ArrayList(Lane) = .empty;
    defer lanes.deinit(allocator);

    for (commits) |commit| {
        _ = findLane(
            lanes.items,
            commit.id,
        );
    }
}

/// Represents the connection to a specific commit
/// in a commit graph
pub const Lane = struct {
    target: ?[]const u8 = null,
};

/// Finds the corresponding lane index for a commit, if exists.
fn findLane(lanes: []const Lane, commit_id: []const u8) ?usize {
    for (lanes, 0..) |lane, idx| {
        if (lane.target) |target| {
            if (std.mem.eql(u8, target, commit_id)) {
                return idx;
            }
        }
    }
}
