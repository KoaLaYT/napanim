const std = @import("std");
const raylib = @import("c").raylib;
const PluginApi = @import("plugin_api.zig").Api;

const State = struct {
    const GPA = std.heap.DebugAllocator(.{});

    gpa: GPA,

    sprite: Sprite,

    fn create() !*State {
        var gpa = GPA.init;
        const state = try gpa.allocator().create(State);

        state.gpa = gpa;
        state.load_resource();

        return state;
    }

    fn destory(self: *State) void {
        self.unload_resource();

        var gpa = self.gpa;
        gpa.allocator().destroy(g_state);
        _ = gpa.deinit();
    }

    fn load_resource(self: *State) void {
        self.sprite = Sprite.load("./assets/sprite.png");
    }

    fn unload_resource(self: *State) void {
        self.sprite.unload();
    }
};

const Sprite = struct {
    texture: raylib.struct_Texture,
    width: f32,
    height: f32,
    total_frame: usize,
    time: f32,
    duration: f32,
    scale: f32,

    fn load(path: []const u8) Sprite {
        const texture = raylib.LoadTexture(path.ptr);
        return .{
            .texture = texture,
            .width = 100,
            .height = 89,
            .total_frame = 20,
            .time = 0.0,
            .duration = 3.0,
            .scale = 3.0,
        };
    }

    fn unload(self: *Sprite) void {
        raylib.UnloadTexture(self.texture);
    }

    fn size(self: *Sprite) struct { f32, f32 } {
        return .{
            self.scale * self.width,
            self.scale * self.height,
        };
    }

    fn draw(self: *Sprite, dt: f32, x_pos: f32, y_pos: f32) void {
        self.time += dt;
        self.time = @mod(self.time, self.duration);

        const idx = (self.time / self.duration) * @as(f32, @floatFromInt(self.total_frame));

        raylib.DrawTexturePro(
            self.texture,
            .{
                .x = self.width * @floor(idx),
                .y = 0,
                .width = self.width,
                .height = self.height,
            },
            .{
                .x = x_pos,
                .y = y_pos,
                .width = self.scale * self.width,
                .height = self.scale * self.height,
            },
            .{ .x = 0, .y = 0 },
            0,
            raylib.WHITE,
        );
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
    g_state.unload_resource();
    return @ptrCast(g_state);
}

fn post_reload(state: *anyopaque) callconv(.c) void {
    raylib.TraceLog(raylib.LOG_INFO, "plugin post reload");
    g_state = @as(*State, @ptrCast(@alignCast(state)));
    g_state.load_resource();
}

fn update() callconv(.c) void {
    raylib.ClearBackground(raylib.BLACK);

    const width: f32 = @floatFromInt(raylib.GetScreenWidth());
    const height: f32 = @floatFromInt(raylib.GetScreenHeight());
    const sprite_width, const sprite_height = g_state.sprite.size();

    const x_pos = width / 2 - sprite_width / 2;
    const y_pos = height / 2 - sprite_height / 2;

    const dt = raylib.GetFrameTime();
    g_state.sprite.draw(dt, x_pos, y_pos);
}

// fn log() void {
//     raylib.TraceLog(raylib.LOG_INFO, "Time: %f", raylib.GetTime());
// }

export const api: PluginApi = .{
    .init = init,
    .deinit = deinit,
    .pre_reload = pre_reload,
    .post_reload = post_reload,
    .update = update,
};
