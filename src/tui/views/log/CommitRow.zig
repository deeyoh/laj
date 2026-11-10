const CommitRow = @This();

const std = @import("std");
const vaxis = @import("vaxis");
const Commit = @import("../../../core/Commit.zig");

commit: *const Commit,

/// Height of the selectable commit, excluding trailing elision lines.
pub fn height(self: CommitRow) usize {
    for (self.commit.graph_lines, 0..) |graph, index| {
        if (std.mem.findScalar(u8, graph, '~') != null) return index;
    }
    return self.totalHeight();
}

/// Includes non-selectable graph decorations following the commit.
pub fn totalHeight(self: CommitRow) usize {
    return @max(@as(usize, 2), self.commit.graph_lines.len);
}

pub fn draw(
    self: CommitRow,
    window: vaxis.Window,
    is_highlighted: bool,
    first_line: usize,
) void {
    const base_style: vaxis.Style = .{
        .bg = if (is_highlighted) .{ .index = 8 } else .default,
    };

    // Fill trailing blank space as well as the text's background.
    window.fill(.{
        .char = .{ .grapheme = " ", .width = 1 },
        .style = base_style,
    });

    var change_style = base_style;
    change_style.fg = .{ .index = 5 };
    change_style.bold = true;

    var hash_style = base_style;
    hash_style.fg = .{ .index = 6 };

    var author_style = base_style;
    author_style.fg = .{ .index = 3 };

    var node_style = base_style;
    node_style.fg = .{ .index = 2 };

    var elision_style = base_style;
    elision_style.fg = .{ .index = 245 };

    // Preserve connector and elision lines, including when the row is clipped.
    for (self.commit.graph_lines, 0..) |graph, line_index| {
        if (line_index < first_line) continue;
        const y = line_index - first_line;
        if (y >= window.height) break;

        const label = "(elided revisions)";
        const label_start = std.mem.find(u8, graph, label);
        const graph_prefix = if (label_start) |start| graph[0..start] else graph;
        _ = window.printSegment(.{
            .text = graph_prefix,
            .style = node_style,
        }, .{ .row_offset = @intCast(y), .wrap = .none });

        if (std.mem.findScalar(u8, graph, '~') != null) {
            const column = window.gwidth(graph_prefix) + @as(usize, if (label_start == null) 1 else 0);
            if (column < window.width) {
                _ = window.printSegment(.{
                    .text = label,
                    .style = elision_style,
                }, .{
                    .row_offset = @intCast(y),
                    .col_offset = @intCast(column),
                    .wrap = .none,
                });
            }
        }
    }

    var lines = std.mem.splitScalar(u8, self.commit.description, '\n');
    const short_hash = self.commit.commit_id[0..@min(self.commit.commit_id.len, 8)];

    const summary = lines.next() orelse "";
    const description = if (summary.len == 0) "(no description)" else summary;

    if (first_line == 0) _ = window.print(&.{
        .{ .text = if (self.commit.graph_lines.len > 0) self.commit.graph_lines[0] else "", .style = node_style },
        .{ .text = self.commit.display_id, .style = change_style },
        .{ .text = " ", .style = base_style },
        .{ .text = short_hash, .style = hash_style },
        .{ .text = " ", .style = base_style },
        .{ .text = self.commit.author.name, .style = author_style },
    }, .{ .row_offset = 0, .wrap = .none });

    if (first_line <= 1 and 1 - first_line < window.height) {
        const row: u16 = @intCast(1 - first_line);
        const graph = if (self.commit.graph_lines.len > 1) self.commit.graph_lines[1] else "";
        // Do not overwrite an elision annotation on this line.
        if (std.mem.findScalar(u8, graph, '~') != null) return;

        // jj trims trailing spaces from graph-only lines. Align the description
        // with the details, without overwriting a wider connector prefix.
        const header_graph = if (self.commit.graph_lines.len > 0) self.commit.graph_lines[0] else "";
        const column = @max(window.gwidth(header_graph), window.gwidth(graph) + 1);
        if (column < window.width) {
            _ = window.printSegment(.{
                .text = description,
                .style = base_style,
            }, .{
                .row_offset = row,
                .col_offset = column,
                .wrap = .none,
            });
        }
    }
}
