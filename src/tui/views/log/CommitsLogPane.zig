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

    const viewport_height: usize = content.height;

    if (commits.len == 0) {
        self.selected_index = 0;
        self.scroll = 0;
        return;
    }

    if (viewport_height == 0) return;

    // Keep selection valid if the commit list shrinks.
    self.selected_index = @min(self.selected_index, commits.len - 1);

    var total_height: usize = 0;
    var selected_start: usize = 0;
    for (commits, 0..) |*commit, index| {
        if (index == self.selected_index) selected_start = total_height;
        total_height += (CommitRow{ .commit = commit }).totalHeight();
    }
    const selected_height = (CommitRow{ .commit = &commits[self.selected_index] }).height();
    const selected_end = selected_start + selected_height;

    if (viewport_height < selected_height) {
        self.scroll = selected_start;
    } else if (selected_start < self.scroll) {
        self.scroll = selected_start;
    } else if (selected_end > self.scroll + viewport_height) {
        self.scroll = selected_end - viewport_height;
    }

    // Clamp after resizing or shrinking the commit list.
    const max_scroll = total_height -| viewport_height;
    self.scroll = @min(self.scroll, max_scroll);

    var offset: usize = 0;
    for (commits, 0..) |*commit, index| {
        const block_start = offset;
        const row = CommitRow{ .commit = commit };
        const commit_end = block_start + row.height();
        offset += row.totalHeight();

        if (offset <= self.scroll) continue;
        if (block_start >= self.scroll + viewport_height) break;

        // Draw the selectable commit and its trailing graph decorations as
        // separate regions. Decorations never inherit the selection highlight.
        const starts = .{ block_start, commit_end };
        const ends = .{ commit_end, offset };
        inline for (0..2) |region| {
            const visible_start = @max(starts[region], self.scroll);
            const visible_end = @min(ends[region], self.scroll + viewport_height);
            if (visible_start < visible_end) {
                const row_window = content.child(.{
                    .x_off = 0,
                    .y_off = @intCast(visible_start - self.scroll),
                    .width = content.width,
                    .height = @intCast(visible_end - visible_start),
                });
                row.draw(
                    row_window,
                    region == 0 and index == self.selected_index,
                    visible_start - block_start,
                );
            }
        }
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
