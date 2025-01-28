const std = @import("std");
const wws = @import("wws");

const examples = &[_]Example{
    .{
        .name = "basic",
        .source = "src/basic.zig",
    },
    .{
        .name = "envs",
        .source = "src/envs.zig",
        .features = .{
            .vars = &.{
                .{ .name = "MESSAGE", .value = "Hello! This message comes from an environment variable" },
            },
        },
    },
    .{
        .name = "workerkv",
        .source = "src/worker-kv.zig",
        .features = .{ .kv = .{ .namespace = "workerkv" } },
    },
    .{
        .name = "no-alloc-kv",
        .source = "src/no-alloc-kv.zig",
        .features = .{ .kv = .{ .namespace = "workerkv" } },
    },
    .{
        .name = "mixed-alloc-kv",
        .source = "src/mixed-alloc-kv.zig",
        .features = .{ .kv = .{ .namespace = "workerkv" } },
    },
    .{
        .name = "mount",
        .source = "src/mount.zig",
        .features = .{
            .folders = &.{
                .{
                    .from = "./_images",
                    .to = "/src/images",
                },
            },
        },
    },
    .{
        .name = "params",
        .source = "src/params.zig",
        .path = "params/[id]",
    },
};

const Example = struct {
    name: []const u8,
    source: []const u8,
    path: ?[]const u8 = null,
    features: ?wws.Features = null,
};

pub fn build(b: *std.Build) !void {
    const target = wws.getTarget(b);
    const optimize = b.standardOptimizeOption(.{});

    const wws_dep = b.dependency("wws", .{});

    const wf = b.addWriteFiles();

    inline for (examples) |e| {
        const worker = try wws.addWorker(b, .{
            .name = e.name,
            .path = e.path orelse e.name,
            .root_source_file = b.path(e.source),
            .target = target,
            .optimize = optimize,
            .wws = wws_dep,
            .features = e.features orelse .{},
        });

        try worker.addToWriteFiles(b, wf);
    }

    // Add folder for mount example
    _ = wf.addCopyFile(b.path("src/_images/zig.svg"), "_images/zig.svg");

    const install = b.addInstallDirectory(.{
        .source_dir = wf.getDirectory(),
        .install_dir = .prefix,
        .install_subdir = "root",
    });

    b.getInstallStep().dependOn(&install.step);
}
