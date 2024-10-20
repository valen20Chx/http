const std = @import("std");

pub const Method = enum {
    GET,
    POST,

    pub fn fromString(methodStr: []const u8) ?@This() {
        const versionMap = std.StaticStringMap(@This()).initComptime(.{
            .{ "GET", .GET },
            .{ "POST", .POST },
        });

        return versionMap.get(methodStr);
    }
};
