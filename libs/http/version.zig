const std = @import("std");

pub const Version = enum {
    HTTP_0_9,
    HTTP_1_0,

    pub fn fromString(versionStr: []const u8) ?@This() {
        const versionMap = std.StaticStringMap(@This()).initComptime(.{
            .{ "HTTP/0.9", .HTTP_0_9 },
            .{ "HTTP/1.0", .HTTP_1_0 },
        });

        return versionMap.get(versionStr);
    }
};
