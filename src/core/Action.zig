const std = @import("std");
const vaxis = @import("std");
const LajTui = @import("../tui/LajTui.zig");

const PaneFocus = enum {
    left_pane,
    right_pane,
};

pub const Scope = enum { app, log };

pub const Action = union(enum) {
    cycle_pane_focus: PaneFocus,
    // quit: void,

    pub fn scope(action: Action) Scope {
        return switch (action) {
            .cycle_pane_focus => .app,
        };
    }
};

/// Returns a action union type that only contains actions that
/// belong to the provided scope argument.
///
/// https://mitchellh.com/writing/zig-comptime-tagged-union-subset
pub fn ScopedAction(comptime s: Scope) type {
    const info = @typeInfo(Action).@"union";

    var i: usize = 0;
    var field_names: [info.field_names.len][]const u8 = undefined;
    var field_types: [info.field_names.len]type = undefined;

    for (info.field_names, info.field_types) |name, T| {
        const action = @unionInit(Action, name, undefined);

        if (action.scope() == s) {
            field_names[i] = name;
            field_types[i] = T;
            i += 1;
        }
    }

    var values: [i]usize = undefined;
    for (&values, 0..) |*value, index| {
        value.* = index;
    }

    const Tag = @Enum(
        usize,
        .exhaustive,
        field_names[0..i],
        &values,
    );

    return @Union(
        .auto,
        Tag, //makes it a tagged union
        field_names[0..i],
        field_types[0..i],
        &@splat(.{}),
    );
}

pub fn performTuiAction(tui: *LajTui, action: ScopedAction(.app)) void {
    switch (action) {
        .cycle_pane_focus => tui.cyclePaneFocus(),
    }
}
