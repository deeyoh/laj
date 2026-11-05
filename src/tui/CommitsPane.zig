const CommitsPane = @This();

const vaxis = @import("vaxis");
const Rect = @import("layout.zig").Rect;
const Pane = @import("Pane.zig");
const Commit = @import("../core/Commit.zig");

const CommitRow = @import("commits/Row.zig");

selected_index: usize = 0,
scroll: usize = 0,

pub fn draw(
    self: *CommitsPane,
    root: vaxis.Window,
    layout: Rect,
    isFocused: bool,
    commits: []const Commit,
) void {
    const content = (Pane {
        .title = "Commits",
        .rect = layout,
        .isFocused = isFocused,
    }).draw(root);

    const row_height: usize = 2;
    for (commits, 0..) |*commit, index| {
        const y = index * row_height;
        if (index >= content.height) break;

        const row_window = content.child(.{
            .x_off = 0,
            .y_off = @intCast(y),
            .width = content.width,
            .height = @intCast(@min(
                row_height,
                content.height - y,
            )),
        });

        const row = CommitRow{
            .commit = commit
        };

        row.draw(row_window, index == self.selected_index);
    }
}

pub fn nextCommitRow(self: *CommitsPane, commit_count: usize) void {
    if (commit_count == 0) return;

    if (self.selected_index < commit_count - 1) {
        self.selected_index += 1;
    }
}

pub fn prevCommitRow(self: *CommitsPane, commit_count: usize) void {
    if (commit_count == 0) return;

    if (self.selected_index > 0 ) {
        self.selected_index -= 1;
    }
}
