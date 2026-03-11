const std = @import("std");
const raylib = @import("c").raylib;
const rlgl = @import("c").rlgl;
const Plugin = @import("plugin_api.zig").Plugin;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    raylib.InitWindow(720, 720, "napanim");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);
    raylib.SetExitKey(raylib.KEY_Q);

    // const plugin_name = "plugin_sprite";
    const plugin_name = "plugin_bone2d";

    var plugin = try Plugin.init(allocator, "zig-out/lib/lib" ++ plugin_name ++ ".dylib");
    defer plugin.deinit();

    while (!raylib.WindowShouldClose()) {
        try plugin.maybe_reload();

        raylib.BeginDrawing();
        plugin.update();
        raylib.EndDrawing();
    }
}
