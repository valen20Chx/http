const std = @import("std");

pub const Request = struct {
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

const HTTP_Parse_Error = error{ NoNewLine, NoMethod, WrongMethod, NoPath, WrongVersion, Unexpected };

pub fn parseRequestStr(_allocator: std.mem.Allocator, data: []const u8) HTTP_Parse_Error!Request {
    var linesIt = std.mem.tokenizeAny(u8, data, "\n");
    const first_line = linesIt.next() orelse return HTTP_Parse_Error.NoNewLine;
    var it = std.mem.tokenizeAny(u8, first_line, " ");

    const method_str = it.next() orelse return HTTP_Parse_Error.NoMethod;
    const method = Request.Method.fromString(method_str) orelse return HTTP_Parse_Error.WrongMethod;

    const path_unmut = it.next() orelse return error.NoPath;
    const path: []u8 = _allocator.alloc(u8, path_unmut.len) catch return HTTP_Parse_Error.Unexpected;
    std.mem.copyForwards(u8, path, path_unmut);

    const version_str = it.next() orelse "HTTP/0.9";
    const version = Request.Version.fromString(version_str) orelse return HTTP_Parse_Error.WrongVersion;

    return Request.init(_allocator, .{
        .method = method,
        .path = path,
        .version = version,
    }) catch return HTTP_Parse_Error.Unexpected;
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
    try std.testing.expect(request.version == Request.Version.HTTP_0_9);
}

test "Parse HTTP 0.9: Wrong Method" {
    const request_str =
        \\NOTHING /this/is/a/path.html
    ;

    const allocator = std.heap.page_allocator;

    const request = parseRequestStr(allocator, request_str);
    try std.testing.expect(request == HTTP_Parse_Error.WrongMethod);
}

test "Parse HTTP 1.0 : Version" {
    const request_str =
        \\GET /this/is/a/path.html HTTP/1.0
    ;

    const allocator = std.heap.page_allocator;

    const request = try parseRequestStr(allocator, request_str);
    defer request.deinit();

    try std.testing.expect(request.method == Request.Method.GET);
    try std.testing.expect(std.mem.eql(u8, request.path, "/this/is/a/path.html"));
    try std.testing.expect(request.version == Request.Version.HTTP_1_0);
}

test "Parse HTTP 1.0 : POST Method" {
    const request_str =
        \\POST /this/is/a/path.html HTTP/1.0
    ;

    const allocator = std.heap.page_allocator;

    const request = try parseRequestStr(allocator, request_str);
    defer request.deinit();

    try std.testing.expect(request.method == Request.Method.POST);
    try std.testing.expect(std.mem.eql(u8, request.path, "/this/is/a/path.html"));
    try std.testing.expect(request.version == Request.Version.HTTP_1_0);
}
