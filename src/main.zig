const std = @import("std");
const raylib = @import("c").raylib;
const Plugin = @import("plugin_api.zig").Plugin;

pub fn main() !void {
    raylib.InitWindow(600, 600, "napanim");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);
    raylib.SetExitKey(raylib.KEY_Q);

    var plugin = try Plugin.init("zig-out/lib/libplugin_sprite.dylib");
    defer plugin.deinit();

    while (!raylib.WindowShouldClose()) {
        try plugin.maybe_reload();

        raylib.BeginDrawing();
        plugin.update();
        raylib.EndDrawing();
    }
}
