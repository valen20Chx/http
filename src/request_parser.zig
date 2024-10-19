const std = @import("std");

pub const HTTP_Method = enum { GET };

pub const Request = struct {
    method: HTTP_Method,
    path: []u8,
    _allocator: std.mem.Allocator,

    pub fn init(_allocator: std.mem.Allocator, data: []const u8) !@This() {
        var linesIt = std.mem.tokenizeAny(u8, data, "\n");
        const first_line = linesIt.next() orelse return error.NoNewLine;
        var it = std.mem.tokenizeAny(u8, first_line, " ");

        const method_str = it.next() orelse return error.NoMethod;
        const method = if (std.mem.eql(u8, method_str, "GET"))
            HTTP_Method.GET
        else
            return error.WrongMethod;

        const path_unmut = it.next() orelse return error.NoPath;
        const path: []u8 = try _allocator.alloc(u8, path_unmut.len);
        std.mem.copyForwards(u8, path, path_unmut);

        return @This(){
            .method = method,
            .path = path,
            ._allocator = _allocator,
        };
    }

    pub fn deinit(self: @This()) void {
        self._allocator.free(self.path);
    }
};

test "Parse HTTP 0.9" {
    const request_str =
        \\GET /this/is/a/path.html
    ;

    const allocator = std.heap.page_allocator;

    const request = try Request.init(allocator, request_str);
    defer request.deinit();

    try std.testing.expect(request.method == HTTP_Method.GET);
    try std.testing.expect(std.mem.eql(u8, request.path, "/this/is/a/path.html"));
}
