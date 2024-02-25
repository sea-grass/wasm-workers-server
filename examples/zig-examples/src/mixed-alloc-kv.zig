const std = @import("std");
const wws = @import("wws");

const tmpl =
    \\<!DOCTYPE html>
    \\<head>
    \\<title>
    \\Wasm Workers Server - KV example</title>
    \\<meta name="viewport" content="width=device-width,initial-scale=1">
    \\<meta charset="UTF-8">
    \\</head>
    \\<body>
    \\<h1>Key / Value store in Zig</h1>
    \\<p>Counter: {d}</p>
    \\<p>This page was generated by a Zig⚡️ file running in WebAssembly.</p>
    \\</body>
;

fn handle(arena: std.mem.Allocator, request: wws.Request) !wws.Response {
    const value = request.kv.map.get("counter") orelse "0";
    var counter = std.fmt.parseInt(i32, value, 10) catch 0;

    counter += 1;

    const body = try std.fmt.allocPrint(arena, tmpl, .{counter});

    var response = wws.Response{
        .data = body,
    };

    const num_s = try std.fmt.allocPrint(arena, "{d}", .{counter});
    try response.kv.map.put(arena, "counter", num_s);

    try response.headers.map.put(arena, "x-generated-by", "wasm-workers-server");

    return response;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    var sfa = std.heap.stackFallback(4096 * 2, arena.allocator());
    const allocator = sfa.get();

    const parse_result = wws.parseStream(allocator, .{}) catch {
        std.debug.print("Failed to read request\n", .{});
        return error.ReadRequestFailed;
    };
    defer parse_result.deinit();

    const request = parse_result.value;
    const response = handle(allocator, request) catch {
        std.debug.print("Failed to handle request\n", .{});
        return error.HandleRequestFailed;
    };

    const stdout = std.io.getStdOut();
    wws.writeResponse(response, stdout.writer()) catch {
        std.debug.print("Failed to write response\n", .{});
        return error.WriteResponseFailed;
    };
}