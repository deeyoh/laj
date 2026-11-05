const CommitsDetailsPane = @This();

const vaxis = @import("vaxis");
const Rect = @import("../../layout.zig").Rect;
const Pane = @import("../../Pane.zig");

pub fn draw(
    self: *CommitsDetailsPane,
    root: vaxis.Window,
    space: Rect,
    has_focus: bool,
) void {
    _ = self;

    _ = (Pane {
        .title = "Details",
        .rect = space,
        .is_focused = has_focus,
    }).draw(root);

    
}
