const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const c_mod = b.addModule("c", .{
        .root_source_file = b.path("src/c.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    c_mod.addIncludePath(b.path("thirdparty/raylib-5.5_macos/include"));
    c_mod.addObjectFile(b.path("thirdparty/raylib-5.5_macos/lib/libraylib.dylib"));
    c_mod.addRPath(b.path("thirdparty/raylib-5.5_macos/lib"));
    c_mod.linkFramework("Cocoa", .{});
    c_mod.linkFramework("IOKit", .{});
    // c_mod.linkFramework("CoreVideo", .{});
    // c_mod.linkFramework("OpenGL", .{});

    const build_plugin_step = b.step("plugin", "Build the plugin");
    const plugin_lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "plugin_sprite",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/plugin_sprite.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "c", .module = c_mod },
            },
        }),
    });
    const install_plugin_lib = b.addInstallArtifact(plugin_lib, .{});
    build_plugin_step.dependOn(&install_plugin_lib.step);

    const exe = b.addExecutable(.{
        .name = "napanim",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "c", .module = c_mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.step.dependOn(&install_plugin_lib.step);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
