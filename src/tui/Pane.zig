const Pane = @This();

const vaxis = @import("vaxis");
const Rect = @import("layout.zig").Rect;

title: []const u8,
rect: Rect,
is_focused: bool = false,

pub fn draw(self: Pane, root: vaxis.Window) vaxis.Window {
    const border_style: vaxis.Style = .{
        .fg = if (self.is_focused) .{ .index = 12 } else .{ .index = 8 },
    };

    const content = root.child(.{
        .x_off = @intCast(self.rect.x),
        .y_off = @intCast(self.rect.y),
        .width = self.rect.width,
        .height = self.rect.height,
        .border = .{
            .where = .all,
            .style = border_style,
            .glyphs = .single_square,
        },
    });

    _ = content.printSegment(.{
        .text = self.title,
        .style = .{ .bold = true },
    }, .{
        .row_offset = 0,
        .col_offset = 0,
        .wrap = .none
    });

    return content;
}
