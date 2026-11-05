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
    const base_style: vaxis.Style = .{
        .bg = if (isHighlighted) .{ .index = 8 } else .default,
    };

    // Fill trailing blank space as well as the text's background.
    window.fill(.{
        .char = .{ .grapheme = " ", .width = 1 },
        .style = base_style,
    });

    var change_style = base_style;
    change_style.fg = .{ .index = 5 };
    change_style.bold = true;

    var hash_style = base_style;
    hash_style.fg = .{ .index = 6 };

    var author_style = base_style;
    author_style.fg = .{ .index = 3 };

    var node_style = base_style;
    node_style.fg = .{ .index = 2 };

    var lines = std.mem.splitScalar(u8, self.commit.description, '\n');
    const first_line = lines.next() orelse "";
    const description = if (first_line.len == 0) "(no description)" else first_line;
    const short_hash = self.commit.commit_id[0..@min(self.commit.commit_id.len, 8)];

    _ = window.print(&.{
        .{ .text = "○ ", .style = node_style },
        .{ .text = self.commit.display_id, .style = change_style },
        .{ .text = " ", .style = base_style },
        .{ .text = short_hash, .style = hash_style },
        .{ .text = " ", .style = base_style },
        .{ .text = self.commit.author.name, .style = author_style },
        .{ .text = "  ", .style = base_style },
    }, .{ 
        .row_offset = 0,
        .wrap = .none 
    });

    if (window.height > 1) {
        _ = window.printSegment(.{
            .text = description,
            .style = base_style,
        }, .{
            .row_offset = 1,
            .col_offset = 2,
            .wrap = .none,
        });
    }
}
