const CommitsLogPane = @This();

const std = @import("std");
const vaxis = @import("vaxis");
const Rect = @import("../../layout.zig").Rect;
const Pane = @import("../../Pane.zig");
const Commit = @import("../../../core/Commit.zig");
const CommitRow = @import("CommitRow.zig");

selected_index: usize = 0,
scroll: usize = 0,

pub fn draw(
    self: *CommitsLogPane,
    root: vaxis.Window,
    space: Rect,
    has_focus: bool,
    commits: []const Commit,
) void {
    const content = (Pane {
        .title = "Commits",
        .rect = space,
        .is_focused = has_focus,
    }).draw(root);

    const row_height: usize = 2;
    const viewport_height: usize = content.height;

    if (commits.len == 0) {
        self.selected_index = 0;
        self.scroll = 0;
        return;
    }

    if (viewport_height == 0) return;

    // Keep selection valid if the commit list shrinks.
    self.selected_index = @min(self.selected_index, commits.len - 1);

    const selected_start = self.selected_index * row_height;
    const selected_end = selected_start + row_height;

    if (viewport_height < row_height) {
        self.scroll = selected_start;
    } else if (selected_start < self.scroll) {
        self.scroll = selected_start;
    } else if (selected_end > self.scroll + viewport_height) {
        self.scroll = selected_end - viewport_height;
    }

    // Clamp after resizing or shrinking the commit list.
    const total_height = commits.len * row_height;
    const max_scroll = total_height -| viewport_height;
    self.scroll = @min(self.scroll, max_scroll);

    var offset: usize = 0;
    for (commits, 0..) |*commit, index| {
        const block_start = offset;
        offset += row_height;

        if (offset <= self.scroll) continue;
        const visible_start = @max(block_start, self.scroll);
        const y = visible_start - self.scroll;
        if (y >= content.height) break;

        const row_window = content.child(.{
            .x_off = 0,
            .y_off = @intCast(y),
            .width = content.width,
            .height = @intCast(@min(offset - visible_start, content.height - y)),
        });

        const row = CommitRow{
            .commit = commit
        };

        row.draw(row_window, index == self.selected_index, visible_start - block_start);
    }
}

pub fn nextCommitRow(self: *CommitsLogPane, commit_count: usize) void {
    if (commit_count == 0) return;

    if (self.selected_index < commit_count - 1) {
        self.selected_index += 1;
    }
}

pub fn prevCommitRow(self: *CommitsLogPane, commit_count: usize) void {
    if (commit_count == 0) return;

    if (self.selected_index > 0 ) {
        self.selected_index -= 1;
    }
}

pub fn lastRow(self: *CommitsLogPane, commit_count: usize) void {
    if (commit_count == 0) return;
    self.selected_index = commit_count - 1;
}
