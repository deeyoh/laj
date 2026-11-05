const Header = @This();

const vaxis = @import("vaxis");
const Rect = @import("layout.zig").Rect;


pub fn draw(
    self: *Header,
    root: vaxis.Window,
    layout_component: Rect,
) void {
    _ = self;

    const header = root.child(.{
        .x_off = @intCast(layout_component.x),
        .y_off = @intCast(layout_component.y),
        .width = @intCast(layout_component.width),
        .height = @intCast(layout_component.height),
    });

    _ = header.printSegment(.{
        .text = "Laj",
        .style = .{ .bold = true },
    }, .{
        .wrap = .none
    });
}
