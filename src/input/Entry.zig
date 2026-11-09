const Entry = @This();

const std = @import("std");
const Binding = @import("Binding.zig");
const Behaviors = @import("../corepkg.zig").Behaviors;

value: Value,

pub const Value = union(enum) {
    keybind: Binding,
    behavior: Behaviors.Value,
};


/// Parses a given line entry into its respective type, ensuring 
/// that the arguments are valid.
pub fn parseAndApply(
    bindings: *Binding.Set,
    behaviors: *Behaviors,
    alloc: std.mem.Allocator,
    entry_type: []const u8,
    entry_value: []const u8
) !void {
    const tag = std.meta.stringToEnum(
        std.meta.Tag(Value),
        entry_type
    ) orelse return error.UnknownEntryType;

    switch (tag) {
        .keybind => try bindings.parseAndPut(alloc, entry_value),
        .behavior => {
            const requested_behavior = try Behaviors.parse(entry_value);
            behaviors.apply(requested_behavior);
        }
    }
}
