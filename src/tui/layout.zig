const std = @import("std");

pub const Rect = struct {
    x: u16,
    y: u16,
    width: u16,
    height: u16,
};

pub const ContentSection = struct {
    left_section: Rect,
    right_section: Rect,
};

pub const Layout = struct {
    header: Rect,
    content_section: ContentSection,
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

        return .{
            .header = .{
                .x = 0,
                .y = 0,
                .width = width,
                .height = header_height,
            },
            .content_section = .{
                .left_section = .{
                    .x = 0,
                    .y = header_height,
                    .width = lw,
                    .height = content_height,
                },

                .right_section = .{
                    .x = lw,
                    .y = header_height,
                    .width = rw,
                    .height = content_height
                },
            },
            .footer = .{
                .x = 0,
                .y = height - footer_height,
                .width = width,
                .height = footer_height,
            },
        };
    }
};
