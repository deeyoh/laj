const std = @import("std");
const vaxis = @import("std");
const LajTui = @import("../tui/LajTui.zig");
const ScopedUnion = @import("scoped_union.zig").ScopedUnion;

const PaneFocus = enum {
    left_pane,
    right_pane,
};

pub const Scope = enum { app, log };

pub const Action = union(enum) {
    cycle_pane_focus: PaneFocus,
    motion_up: void,
    motion_down: void,
    // quit: void,

    pub fn scope(action: Action) Scope {
        return switch (action) {
            .cycle_pane_focus => .app,
        };
    }
};

/// Parses a given action input to check if is a valid action.
pub fn parse(action_text: []const u8) !std.meta.Tag(Action) {
    return std.meta.stringToEnum(
        std.meta.Tag(Action),
        action_text,
    ) orelse error.InvalidAction;
}


pub fn performTuiAction(tui: *LajTui, action: ScopedUnion(.app, Action)) void {
    switch (action) {
        .cycle_pane_focus => tui.cyclePaneFocus(),
    }
}
