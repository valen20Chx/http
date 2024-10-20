const std = @import("std");

pub const Request = struct {
    pub const Method = enum { GET };
    pub const Version = enum {
        HTTP_0_9,

        pub fn fromString(versionStr: []const u8) ?@This() {
            const versionMap = std.StaticStringMap(Request.Version).initComptime(.{
                .{ "HTTP/0.9", .HTTP_0_9 },
            });

            return versionMap.get(versionStr);
        }
    };

    version: Version,
    method: Method,
    path: []u8,

    _allocator: std.mem.Allocator,

    pub fn init(_allocator: std.mem.Allocator, data: struct {
        version: Version,
        method: Method,
        path: []const u8,
    }) !@This() {
        const path: []u8 = try _allocator.alloc(u8, data.path.len);
        std.mem.copyForwards(u8, path, data.path);

        return .{ .version = data.version, .method = data.method, .path = path, ._allocator = _allocator };
    }

    pub fn deinit(self: @This()) void {
        self._allocator.free(self.path);
    }
};

pub fn parseRequestStr(_allocator: std.mem.Allocator, data: []const u8) !Request {
    var linesIt = std.mem.tokenizeAny(u8, data, "\n");
    const first_line = linesIt.next() orelse return error.NoNewLine;
    var it = std.mem.tokenizeAny(u8, first_line, " ");

    const method_str = it.next() orelse return error.NoMethod;
    const method = if (std.mem.eql(u8, method_str, "GET"))
        Request.Method.GET
    else
        return error.WrongMethod;

    const path_unmut = it.next() orelse return error.NoPath;
    const path: []u8 = try _allocator.alloc(u8, path_unmut.len);
    std.mem.copyForwards(u8, path, path_unmut);

    const version_str = it.next() orelse "HTTP/0.9";
    const version = Request.Version.fromString(version_str) orelse return error.WrongVersion;

    return Request.init(_allocator, .{
        .method = method,
        .path = path,
        .version = version,
    });
}

test "Parse HTTP 0.9" {
    const request_str =
        \\GET /this/is/a/path.html
    ;

    const allocator = std.heap.page_allocator;

    const request = try parseRequestStr(allocator, request_str);
    defer request.deinit();

    try std.testing.expect(request.method == Request.Method.GET);
    try std.testing.expect(std.mem.eql(u8, request.path, "/this/is/a/path.html"));
}
