const CommitsPane = @This();

const vaxis = @import("vaxis");
const Rect = @import("layout.zig").Rect;
const Pane = @import("Pane.zig");
const Commit = @import("../core/Commit.zig");

pub fn draw(
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

    for (commits, 0..) |commit, index| {
        if (index >= content.height) break;

        _ = content.printSegment(.{
            .text = commit.description,
        }, .{
            .row_offset = @intCast(index),
            .wrap = .none
        });
    }
}


// pub fndraw (
//     root: vaxis.Window,
//     isFocused = 
// ) void {
// }
