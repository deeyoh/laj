const Log = @This();

const vaxis = @import("vaxis");
const PaneFocus = @import("../../LajTui.zig").PaneFocus;
const Commit = @import("../../../core/Commit.zig");
const layout = @import("../../layout.zig");

const CommitsLogPane = @import("CommitsLogPane.zig");
const CommitsDetailsPane = @import("CommitsDetailsPane.zig");

const ContentSection = layout.ContentSection;

commit_log_pane: CommitsLogPane = .{},
commit_details_pane: CommitsDetailsPane = .{},

pub fn draw(
    self: *Log, 
    root: vaxis.Window, 
    content_layout: ContentSection,
    focused_pane: PaneFocus,
    commits: []const Commit
) void {
    self.commit_log_pane.draw(
        root,
        content_layout.left_section,
        focused_pane == .left_section,
        commits,
    );

    self.commit_details_pane.draw(
        root,
        content_layout.right_section,
        focused_pane == .right_section
    );
}
