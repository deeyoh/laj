const LajTui = @This();

const vaxis = @import("vaxis");
const Layout = @import("layout.zig").Layout;
const Pane = @import("Pane.zig");

const Commit = @import("../jj/Commit.zig");

const CommitsPane = @import("CommitsPane.zig");

const ComponentFocus = enum {
    commits,
    details,
    diff,
};

hasFocus: ComponentFocus = .commits,
commits: []const Commit,

pub fn cycleFocus(self: *LajTui) void {
    self.hasFocus = switch (self.hasFocus) {
        .commits => .details,
        .details => .diff,
        .diff => .commits,
    };
}

pub fn draw(self: *LajTui, root: vaxis.Window) void {
    root.clear();
    root.hideCursor();

    const layout = Layout.calculate(
        root.width,
        root.height
    );

    // root.child() creates a drawing region with `root`.
    const header = root.child(.{
        .x_off = @intCast(layout.header.x),
        .y_off = @intCast(layout.header.y),
        .width = @intCast(layout.header.width),
        .height = @intCast(layout.header.height),
    });

    _ = header.printSegment(.{
        .text = " Laj | Jujutsu TUI",
        .style = .{ .bold = true },
    }, .{ .wrap = .none });

    CommitsPane.draw(
        root, 
        layout.commits, 
        self.hasFocus == .commits, 
        self.commits
    );

    _ = (Pane{
        .title = "Change Details",
        .rect = layout.details,
        .isFocused = self.hasFocus == .details
    }).draw(root);

    _ = (Pane{
        .title = "Diff",
        .rect = layout.diff,
        .isFocused = self.hasFocus == .diff
    }).draw(root);

    const footer = root.child(.{
        .x_off = @intCast(layout.footer.x),
        .y_off = @intCast(layout.footer.y),
        .width = @intCast(layout.footer.width),
        .height = @intCast(layout.footer.height),
    });

    _ = footer.printSegment(.{
        .text = "ready",
        .style = .{ .bold = true },
    }, .{ .wrap = .none });
}
