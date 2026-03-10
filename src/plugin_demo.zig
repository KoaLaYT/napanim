const std = @import("std");
const raylib = @import("c").raylib;
const PluginApi = @import("plugin_api.zig").Api;

const State = struct {
    const GPA = std.heap.DebugAllocator(.{});

    gpa: GPA,
    color: raylib.struct_Color,

    fn create() !*State {
        var gpa = GPA.init;
        const state = try gpa.allocator().create(State);
        state.* = .{
            .gpa = gpa,
            .color = raylib.RED,
        };
        return state;
    }

    fn destory(self: *State) void {
        var gpa = self.gpa;
        gpa.allocator().destroy(g_state);
        _ = gpa.deinit();
    }
};

var g_state: *State = undefined;

fn init() callconv(.c) void {
    raylib.TraceLog(raylib.LOG_INFO, "plugin init");
    g_state = State.create() catch unreachable;
}

fn deinit() callconv(.c) void {
    g_state.destory();
}

fn pre_reload() callconv(.c) *anyopaque {
    raylib.TraceLog(raylib.LOG_INFO, "plugin pre reload");
    return @ptrCast(g_state);
}

fn post_reload(state: *anyopaque) callconv(.c) void {
    raylib.TraceLog(raylib.LOG_INFO, "plugin post reload");
    g_state = @as(*State, @ptrCast(@alignCast(state)));
    g_state.color = raylib.GREEN;
}

fn update() callconv(.c) void {
    raylib.ClearBackground(raylib.BLACK);
    raylib.DrawRectangle(100, 100, 20, 20, g_state.color);
}

export const api: PluginApi = .{
    .init = init,
    .deinit = deinit,
    .pre_reload = pre_reload,
    .post_reload = post_reload,
    .update = update,
};
