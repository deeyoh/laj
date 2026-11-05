const LajTui = @This();

const vaxis = @import("vaxis");
// const Layout = @import("layout.zig").Layout;
// const 
const layout = @import("layout.zig");
const Rect = @import("layout.zig").Rect;
const Pane = @import("Pane.zig");

const Commit = @import("../core/Commit.zig");
const Layout = layout.Layout;
const ContentSection = layout.ContentSection;

const Header = @import("Header.zig");

//views
const Log = @import("views/log/Log.zig");

const RenderCtx = struct {
    root: vaxis.Window,
    content_layout: ContentSection,
    focused_pane: PaneFocus,
    commits: []const Commit,
};

const ActiveView = union(enum) {
    log: Log,

    fn render(self: *ActiveView, ctx: RenderCtx) void {
        switch (self.*) {
            .log => |*log| log.draw(
                ctx.root,
                ctx.content_layout,
                ctx.focused_pane,
                ctx.commits,
            ),

        }
    }
};

pub const PaneFocus = enum {
    left_section,
    right_section,
};


focused_pane: PaneFocus = .left_section,
commits: []const Commit,
active_view: ActiveView = .{ .log = .{} },
header: Header = .{},

//@TODO: Should be later moved into a window action in key handler
pub fn cyclePaneFocus(self: *LajTui) void {
    self.focused_pane = switch (self.focused_pane) {
        .left_section => .right_section,
        .right_section => .left_section,
    };
}

pub fn draw(self: *LajTui, root: vaxis.Window) void {
    root.clear();
    root.hideCursor();

    const tui_layout = Layout.calculate(
        root.width,
        root.height
    );

    self.header.draw(
        root,
        tui_layout.header,
    );

    self.active_view.render(.{
        .root = root,
        .content_layout = tui_layout.content_section,
        .focused_pane = self.focused_pane,
        .commits = self.commits,
    });
    // // self.commits_pane.draw(
    // //     root, 
    // //     layout.commits, 
    // //     self.hasFocus == .commits, 
    // //     self.commits
    // // );
    //
    // _ = (Pane{
    //     .title = "Change Details",
    //     .rect = layout.details,
    //     .isFocused = self.hasFocus == .details
    // }).draw(root);
    //
    // _ = (Pane{
    //     .title = "Diff",
    //     .rect = layout.diff,
    //     .isFocused = self.hasFocus == .diff
    // }).draw(root);
    //
    // const footer = root.child(.{
    //     .x_off = @intCast(layout.footer.x),
    //     .y_off = @intCast(layout.footer.y),
    //     .width = @intCast(layout.footer.width),
    //     .height = @intCast(layout.footer.height),
    // });
    //
    // _ = footer.printSegment(.{
    //     .text = "ready",
    //     .style = .{ .bold = true },
    // }, .{ .wrap = .none });
}
