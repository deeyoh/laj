/// Returns a union type that only contains values that
/// belong to the provided scope argument.
///
/// https://mitchellh.com/writing/zig-comptime-tagged-union-subset
pub fn ScopedUnion(comptime s: anytype, comptime T: type) type {
    const info = @typeInfo(T).@"union";
    var i: usize = 0;
    var field_names: [info.field_names.len][]const u8 = undefined;
    var field_types: [info.field_names.len]type = undefined;

    for (info.field_names, info.field_types) |name, field_type| {
        const action = @unionInit(T, name, undefined);

        if (action.scope() == s) {
            field_names[i] = name;
            field_types[i] = field_type;
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
