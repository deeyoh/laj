const Row = @This();

const std = @import("std");
const vaxis = @import("vaxis");
const Commit = @import("../../core/Commit.zig");


commit: *const Commit,

pub fn draw(
    self: Row,
    window: vaxis.Window,
    isHighlighted: bool,
) void {
    const style: vaxis.Style = .{
        .bg = if (isHighlighted) .{ .index = 4} else .default,
    };

    window.fill(.{
        .char = .{ .grapheme = " ", .width = 1 },
        .style = style,
    });

    _ = window.printSegment(.{
        .text = self.commit.commit_id,
        .style = style,
    }, .{ .wrap = .none });
}
