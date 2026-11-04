const std = @import("std");

pub const Rect = struct {
    x: u16,
    y: u16,
    width: u16,
    height: u16,
};

pub const Layout = struct {
    header: Rect,
    commits: Rect,
    details: Rect,
    diff: Rect,
    footer: Rect,

    pub fn calculate(width: u16, height: u16) Layout {
        const header_height: u16 = @min(height, 1);
        const footer_height: u16 = @min(
            height - header_height,
            1,
        );

        const content_height = height - header_height - footer_height;

        const lw: u16 = @intCast(@as(u32, width) * 35 / 100);
        const rw = width - lw;

        const details_height = content_height / 2;
        const diff_height = content_height - details_height;

        return .{
            .header = .{
                .x = 0,
                .y = 0,
                .width = width,
                .height = header_height,
            },

            .commits = .{
                .x = 0,
                .y = header_height,
                .width = lw,
                .height = content_height,
            },

            .details = .{
                .x = lw,
                .y = header_height,
                .width = rw,
                .height = details_height,
            },

            .diff = .{
                .x = lw,
                .y = diff_height,
                .width = rw,
                .height = diff_height,
            },

            .footer = .{
                .x = width,
                .y = height - footer_height,
                .width = .width,
                .height = footer_height,
            },
        };
    }
};
