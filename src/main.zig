const std = @import("std");
const http = @import("http");

fn loadRessource(alloc: std.mem.Allocator, dir: []const u8, path: []const u8) !void {
    const ressource_path = try std.fmt.allocPrint(alloc, comptime "{s}{s}", .{ dir, path });
    defer alloc.free(ressource_path);

    const file = try std.fs.openFileAbsolute(ressource_path, .{ .mode = .read_only });
    var buf: [1024]u8 = undefined;

    _ = try file.read(&buf);

    std.debug.print("{s}", .{buf});
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const ressource_directory = "/home/valentin/http/res";

    const request_str =
        \\GET /index.html
    ;
    const request = try http.request.parseRequestStr(allocator, request_str);
    defer request.deinit();

    try loadRessource(allocator, ressource_directory, request.path);
}
