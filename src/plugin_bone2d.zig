const std = @import("std");
const raylib = @import("c").raylib;
const rlgl = @import("c").rlgl;
const PluginApi = @import("plugin_api.zig").Api;

const State = struct {
    allocator: std.mem.Allocator,
    skeleton: Skeleton,

    fn create(allocator: std.mem.Allocator) !*State {
        const state = try allocator.create(State);
        errdefer allocator.destroy(state);

        state.allocator = allocator;
        state.skeleton = try Skeleton.create(allocator);

        return state;
    }

    fn destory(self: *State) void {
        const allocator = self.allocator;
        self.skeleton.destory(allocator);
        allocator.destroy(g_state);
    }
};

const Skeleton = struct {
    bones: std.ArrayList(Bone),
    bones_pos: std.ArrayList(BonePosition),
    slots: std.ArrayList(Slot),
    skins: std.ArrayList(Skin),
    animations: std.ArrayList(Animation),
    animation_time: f64,
    animation_playing_idx: isize,
    texture: raylib.struct_Texture,

    fn create(alloc: std.mem.Allocator) !Skeleton {
        const total_size = 8;
        var bones = try std.ArrayList(Bone).initCapacity(alloc, total_size);
        errdefer bones.deinit(alloc);
        bones.addOneAssumeCapacity().* = Bone.init("root", 0, 0.0, 0, 0.0, 0.0);
        bones.addOneAssumeCapacity().* = Bone.init("Body", 0, 538.08, 83.84, 0.0, 229.45);
        bones.addOneAssumeCapacity().* = Bone.init("Head", 1, 467.95, 15.1, 592.82, -3.46);
        bones.addOneAssumeCapacity().* = Bone.init("L_Hand", 1, 175.31, -175.66, 309.27, -172.83);
        bones.addOneAssumeCapacity().* = Bone.init("R_Hand", 1, 166.94, 180.98, 266.69, 170.07);
        bones.addOneAssumeCapacity().* = Bone.init("L_Foot", 0, 290.84, -91.1, 83.88, 322.03);
        bones.addOneAssumeCapacity().* = Bone.init("R_Foot", 0, 280.1, -93.43, -33.6, 309.05);

        var bones_pos = try std.ArrayList(BonePosition).initCapacity(alloc, total_size);
        errdefer bones_pos.deinit(alloc);
        for (0..bones.items.len) |_| {
            bones_pos.addOneAssumeCapacity().* = BonePosition.init;
        }

        var slots = try std.ArrayList(Slot).initCapacity(alloc, 32);
        errdefer slots.deinit(alloc);
        slots.addOneAssumeCapacity().* = Slot.init("L_Hand", 0, 2);
        slots.addOneAssumeCapacity().* = Slot.init("L_Foot", 0, 4);
        slots.addOneAssumeCapacity().* = Slot.init("Body", 0, 0);
        slots.addOneAssumeCapacity().* = Slot.init("BodyObject_01", 0, 8);
        slots.addOneAssumeCapacity().* = Slot.init("Head", 0, 1);
        slots.addOneAssumeCapacity().* = Slot.init("Eye_Basic", 0, 6);
        slots.addOneAssumeCapacity().* = Slot.init("hairObject_01", 0, 7);
        slots.addOneAssumeCapacity().* = Slot.init("R_Foot", 0, 5);
        // slots.addOneAssumeCapacity().* = Slot.init("HandObject_02", 0, 9);
        slots.addOneAssumeCapacity().* = Slot.init("HandObject_04", 0, 10);
        slots.addOneAssumeCapacity().* = Slot.init("R_Hand", 0, 3);

        var skins = try std.ArrayList(Skin).initCapacity(alloc, 32);
        errdefer skins.deinit(alloc);
        skins.addOneAssumeCapacity().* = Skin.init(
            "Body",
            .{ 1, 1, 0, 1, 0, 0, 1, 0 },
            .{ 1, 2, 3, 1, 3, 0 },
            .{
                1, 1, -14.35, -185.68, 1,
                1, 1, -48.28, 128.5,   1,
                1, 1, 533.33, 191.32,  1,
                1, 1, 567.27, -122.85, 1,
            },
            .{ .x = 1367, .y = 1412, .width = 316, .height = 585 },
            true,
        );
        skins.addOneAssumeCapacity().* = Skin.init(
            "Head",
            .{ 1, 1, 0, 1, 0, 0, 1, 0 },
            .{ 1, 2, 3, 1, 3, 0 },
            .{
                1, 2, -56.61, -197.56, 1,
                1, 2, 20.29,  291.43,  1,
                1, 2, 514.22, 213.75,  1,
                1, 2, 437.32, -275.24, 1,
            },
            .{ .x = 496, .y = 229, .width = 495, .height = 500 },
            true,
        );
        skins.addOneAssumeCapacity().* = Skin.init(
            "L_Hand",
            .{ 1, 1, 0, 1, 0, 0, 1, 0 },
            .{ 1, 2, 3, 1, 3, 0 },
            .{
                1, 4, 183.64, 118.6,   1,
                1, 4, 203.72, -102.49, 1,
                1, 4, -17.37, -122.57, 1,
                1, 4, -37.45, 98.52,   1,
            },
            .{ .x = 2, .y = 1617, .width = 222, .height = 222 },
            false,
        );
        skins.addOneAssumeCapacity().* = Skin.init(
            "R_Hand",
            .{ 1, 1, 0, 1, 0, 0, 1, 0 },
            .{ 1, 3, 0, 1, 2, 3 },
            .{
                1, 3, 195.83, 106.32,  1,
                1, 3, 202.91, -115.56, 1,
                1, 3, -18.97, -122.65, 1,
                1, 3, -26.06, 99.24,   1,
            },
            .{ .x = 2, .y = 1617, .width = 222, .height = 222 },
            false,
        );
        skins.addOneAssumeCapacity().* = Skin.init(
            "L_Foot",
            .{ 1, 1, 0, 1, 0, 0, 1, 0 },
            .{ 1, 2, 3, 1, 3, 0 },
            .{
                1, 6, 308.53, 147.55,  1,
                1, 6, 323.02, -94.02,  1,
                1, 6, -21.36, -114.68, 1,
                1, 6, -35.85, 126.89,  1,
            },
            .{ .x = 1020, .y = 1542, .width = 242, .height = 345 },
            true,
        );
        skins.addOneAssumeCapacity().* = Skin.init(
            "R_Foot",
            .{ 1, 1, 0, 1, 0, 0, 1, 0 },
            .{ 1, 2, 3, 1, 3, 0 },
            .{
                1, 5, 321.92, 125.39,  1,
                1, 5, 326.57, -116.56, 1,
                1, 5, -18.37, -123.19, 1,
                1, 5, -23.02, 118.76,  1,
            },
            .{ .x = 1020, .y = 1542, .width = 242, .height = 345 },
            true,
        );
        skins.addOneAssumeCapacity().* = Skin.init(
            "Eye_Basic",
            .{ 1, 1, 0, 1, 0, 0, 1, 0 },
            .{ 1, 2, 3, 1, 3, 0 },
            .{
                1, 2, 153.06, 47.84,  1,
                1, 2, 181.34, 227.63, 1,
                1, 2, 258.39, 215.52, 1,
                1, 2, 230.12, 35.73,  1,
            },
            .{ .x = 370, .y = 1841, .width = 182, .height = 78 },
            false,
        );
        skins.addOneAssumeCapacity().* = Skin.init(
            "hairObject_01",
            .{ 1, 1, 0, 1, 0, 0, 1, 0 },
            .{ 1, 2, 3, 1, 3, 0 },
            .{
                1, 2, 24.84,  -258.96, 1,
                1, 2, 112,    295.23,  1,
                1, 2, 561.47, 224.54,  1,
                1, 2, 474.32, -329.65, 1,
            },
            .{ .x = 1576, .y = 2, .width = 561, .height = 455 },
            true,
        );
        skins.addOneAssumeCapacity().* = Skin.init(
            "BodyObject_01",
            .{ 1, 1, 0, 1, 0, 0, 1, 0 },
            .{ 1, 2, 3, 1, 3, 0 },
            .{
                1, 1, -111.52, -254.51, 1,
                1, 1, -158.98, 184.93,  1,
                1, 1, 549.89,  261.5,   1,
                1, 1, 597.36,  -177.94, 1,
            },
            .{ .x = 1042, .y = 565, .width = 442, .height = 713 },
            true,
        );
        skins.addOneAssumeCapacity().* = Skin.init(
            "HandObject_02",
            .{ 1, 1, 0, 1, 0, 0, 1, 0 },
            .{ 1, 2, 3, 1, 3, 0 },
            .{
                1, 3, 342.47,  -211.06, 1,
                1, 3, -324.48, -416.94, 1,
                1, 3, -436.85, -52.88,  1,
                1, 3, 230.1,   152.99,  1,
            },
            .{ .x = 598, .y = 1159, .width = 698, .height = 381 },
            false,
        );
        skins.addOneAssumeCapacity().* = Skin.init(
            "HandObject_04",
            .{ 1, 1, 0, 1, 0, 0, 1, 0 },
            .{ 1, 2, 3, 0, 1, 3 },
            .{
                1, 3, 373.99,  218.27,  1,
                1, 3, 461.87,  30.85,   1,
                1, 3, -255.22, -305.39, 1,
                1, 3, -343.1,  -117.97, 1,
            },
            .{ .x = 226, .y = 1577, .width = 207, .height = 792 },
            true,
        );

        var animations = try std.ArrayList(Animation).initCapacity(alloc, 32);
        errdefer animations.deinit(alloc);

        animations.addOneAssumeCapacity().* = Animation.idle;
        animations.addOneAssumeCapacity().* = Animation.jump;
        animations.addOneAssumeCapacity().* = Animation.attack;
        animations.addOneAssumeCapacity().* = Animation.death;

        const texture = raylib.LoadTexture("./assets/bone2d/image1.png");

        return .{
            .bones = bones,
            .bones_pos = bones_pos,
            .slots = slots,
            .skins = skins,
            .texture = texture,
            .animations = animations,
            .animation_time = 0,
            .animation_playing_idx = -1,
        };
    }

    fn destory(self: *Skeleton, allocator: std.mem.Allocator) void {
        self.bones.deinit(allocator);
        self.bones_pos.deinit(allocator);
        self.slots.deinit(allocator);
        self.skins.deinit(allocator);
        self.animations.deinit(allocator);
        raylib.UnloadTexture(self.texture);
    }

    fn draw(self: *Skeleton) void {
        self.update_bone_pos();
        self.draw_skin();
    }

    fn anime(self: *Skeleton, idx: isize) void {
        if (self.animation_playing_idx >= 0) return;

        self.animation_playing_idx = idx;
        self.animation_time = raylib.GetTime();
    }

    fn draw_skin(self: *Skeleton) void {
        rlgl.rlBegin(rlgl.RL_TRIANGLES);
        rlgl.rlSetTexture(self.texture.id);

        const width: f32 = @floatFromInt(self.texture.width);
        const height: f32 = @floatFromInt(self.texture.height);

        rlgl.rlColor4ub(255, 255, 255, 255);

        for (self.slots.items) |slot| {
            const skin = self.skins.items[slot.skin_idx];

            // need reverse iterate so that it is CCW
            // cause we flip y at the bottom
            // otherwise backface culling will make it show nothing
            var i: isize = skin.triangles.len - 1;
            while (i >= 0) : (i -= 1) {
                const idx = skin.triangles[@intCast(i)];
                // TODO only support one bone now
                std.debug.assert(@as(usize, @intFromFloat(skin.vertices[idx * 5])) == 1);

                const lu = skin.uvs[idx * 2];
                const lv = skin.uvs[idx * 2 + 1];

                var u: f32 = 0;
                var v: f32 = 0;
                if (skin.is_rotate) {
                    u = (skin.bounds.x + (lv * skin.bounds.height)) / width;
                    v = (skin.bounds.y + ((1 - lu) * skin.bounds.width)) / height;
                } else {
                    u = (skin.bounds.x + (lu * skin.bounds.width)) / width;
                    v = (skin.bounds.y + (lv * skin.bounds.height)) / height;
                }

                const vx = skin.vertices[idx * 5 + 2];
                const vy = skin.vertices[idx * 5 + 3];
                const bone_pos = self.bones_pos.items[@intFromFloat(skin.vertices[idx * 5 + 1])];
                const cos = @cos(bone_pos.rotation * std.math.pi / 180);
                const sin = @sin(bone_pos.rotation * std.math.pi / 180);

                const scale = 0.3;
                const x = 1100 + bone_pos.x + (vx * cos - vy * sin);
                const y = 1800 - (bone_pos.y + (vx * sin + vy * cos));

                rlgl.rlTexCoord2f(u, v);
                rlgl.rlVertex2f(x * scale, y * scale);
            }
        }

        rlgl.rlEnd();
        rlgl.rlSetTexture(0);
    }

    fn update_bone_pos(self: *Skeleton) void {
        const bones = self.bones.items;

        for (0..bones.len) |idx| {
            const bone = bones[idx];
            // TODO currently do not allow out of order render
            std.debug.assert(idx >= bone.parent_idx);

            if (idx == 0) {
                self.bones_pos.items[idx] = .{
                    .length = bone.length,
                    .rotation = bone.rotation,
                    .x = 0,
                    .y = 0,
                };
                continue;
                // root will never be animated
            }

            const parent = self.bones_pos.items[bone.parent_idx];
            const cos = @cos(parent.rotation * std.math.pi / 180);
            const sin = @sin(parent.rotation * std.math.pi / 180);

            var ai_r: f32 = 0;
            var ai_x: f32 = 0;
            var ai_y: f32 = 0;
            // check animation
            if (self.animation_playing_idx >= 0) {
                const animation = self.animations.items[@intCast(self.animation_playing_idx)];
                const dt = raylib.GetTime() - self.animation_time;
                if (dt >= animation.duration) {
                    self.animation_playing_idx = -1;
                    self.animation_time = 0;
                } else {
                    for (0..animation.bone_animation_count) |i| {
                        const bone_animation = animation.bone_animations[i];
                        if (bone_animation.bone_idx != idx) continue;
                        // translate
                        {
                            var ai: usize = 1;
                            while (ai < bone_animation.translate_count) : (ai += 1) {
                                const translate = bone_animation.translates[ai];
                                if (dt < translate.t * animation.duration) break;
                            }
                            const from_t: f32 = bone_animation.translates[ai - 1].t;
                            const from_x: f32 = bone_animation.translates[ai - 1].x;
                            const from_y: f32 = bone_animation.translates[ai - 1].y;
                            const to_t = bone_animation.translates[ai].t;
                            const to_x = bone_animation.translates[ai].x;
                            const to_y = bone_animation.translates[ai].y;
                            const amount = slerp(from_t, to_t, @floatCast(dt / animation.duration));
                            ai_x = lerp(from_x, to_x, amount);
                            ai_y = lerp(from_y, to_y, amount);
                        }
                        // rotate
                        {
                            var ai: usize = 1;
                            while (ai < bone_animation.rotate_count) : (ai += 1) {
                                const translate = bone_animation.rotates[ai];
                                if (dt < translate.t * animation.duration) break;
                            }
                            const from_t: f32 = bone_animation.rotates[ai - 1].t;
                            const from_v: f32 = bone_animation.rotates[ai - 1].v;
                            const to_t = bone_animation.rotates[ai].t;
                            const to_v = bone_animation.rotates[ai].v;
                            const amount = slerp(from_t, to_t, @floatCast(dt / animation.duration));
                            ai_r = lerp(from_v, to_v, amount);
                        }
                    }
                }
            }

            self.bones_pos.items[idx] = .{
                .length = bone.length,
                .rotation = bone.rotation + parent.rotation + ai_r,
                .x = parent.x + (ai_x + bone.x) * cos - (ai_y + bone.y) * sin,
                .y = parent.y + (ai_x + bone.x) * sin + (ai_y + bone.y) * cos,
            };
        }
    }
};

const BonePosition = struct {
    length: f32,
    rotation: f32,
    x: f32,
    y: f32,

    const init: BonePosition = .{
        .length = 0,
        .rotation = 0,
        .x = 0,
        .y = 0,
    };
};

const Bone = struct {
    name: []const u8, // just for debug
    parent_idx: usize,
    length: f32,
    rotation: f32,
    x: f32,
    y: f32,

    fn init(
        name: []const u8,
        parent_idx: usize,
        length: f32,
        rotation: f32,
        x: f32,
        y: f32,
    ) Bone {
        return .{
            .name = name,
            .parent_idx = parent_idx,
            .length = length,
            .rotation = rotation,
            .x = x,
            .y = y,
        };
    }
};

const Slot = struct {
    name: []const u8,
    bone_idx: usize, // TODO, this idx is not used now. need to clarify it more
    skin_idx: usize,

    fn init(
        name: []const u8,
        bone_idx: usize,
        skin_idx: usize,
    ) Slot {
        return .{
            .name = name,
            .bone_idx = bone_idx,
            .skin_idx = skin_idx,
        };
    }
};

// TODO this is just for test
const Skin = struct {
    name: []const u8,
    uvs: [8]f32,
    triangles: [6]usize,
    vertices: [20]f32,
    bounds: raylib.struct_Rectangle,
    is_rotate: bool,

    fn init(
        name: []const u8,
        uvs: [8]f32,
        triangles: [6]usize,
        vertices: [20]f32,
        bounds: raylib.struct_Rectangle,
        is_rotate: bool,
    ) Skin {
        return .{
            .name = name,
            .uvs = uvs,
            .triangles = triangles,
            .vertices = vertices,
            .bounds = bounds,
            .is_rotate = is_rotate,
        };
    }
};

const Animation = struct {
    name: []const u8,
    duration: f64,
    bone_animation_count: usize,
    bone_animations: [16]BoneAnimation,

    const death: Animation = .{
        .name = "death",
        .duration = 2,
        .bone_animation_count = 6,
        .bone_animations = [_]BoneAnimation{
            .{
                .bone_idx = 6, // R_Foot
                .rotates = [_]Rotate{
                    Rotate.init(0, 0),
                    Rotate.init(0.1333, -94.08),
                    Rotate.init(0.2333, -102.08),
                    Rotate.init(1, -102.08),
                } ++ [_]Rotate{.empty} ** 12,
                .rotate_count = 4,
                .translates = [_]Translate{
                    Translate.init(0, 0, 0),
                    Translate.init(0.1333, 0, 9.95),
                    Translate.init(0.2333, 0, -228.9),
                    Translate.init(1, 0, -228.9),
                } ++ [_]Translate{.empty} ** 12,
                .translate_count = 4,
            },
            .{
                .bone_idx = 5, // L_Foot
                .rotates = [_]Rotate{
                    Rotate.init(0, 0),
                    Rotate.init(0.1333, -74.73),
                    Rotate.init(0.2333, -102.59),
                    Rotate.init(1, -102.59),
                } ++ [_]Rotate{.empty} ** 12,
                .rotate_count = 4,
                .translates = [_]Translate{
                    Translate.init(0, 0, 2.49),
                    Translate.init(0.1333, 0, -95.25),
                    Translate.init(0.2333, 0, -253.78),
                    Translate.init(1, 0, -253.78),
                } ++ [_]Translate{.empty} ** 12,
                .translate_count = 4,
            },
            .{
                .bone_idx = 4, // R_Hand
                .translates = [_]Translate{
                    Translate.init(0, 0, 0),
                    Translate.init(0.1333, 95.19, 197.56),
                    Translate.init(0.2333, 164.06, 238.34),
                    Translate.init(0.3667, 28.21, -170.77),
                    Translate.init(1, 28.21, -170.77),
                } ++ [_]Translate{.empty} ** 11,
                .translate_count = 4,
            },
            .{
                .bone_idx = 3, // L_Hand
                .translates = [_]Translate{
                    Translate.init(0, 0, 0),
                    Translate.init(0.1333, 152.64, 356.06),
                    Translate.init(0.2333, 232.99, 424.61),
                    Translate.init(0.3667, 362.45, 158.04),
                    Translate.init(0.4333, 353.35, 130.38),
                    Translate.init(0.5667, 362.45, 158.04),
                    Translate.init(1, 362.45, 158.04),
                } ++ [_]Translate{.empty} ** 9,
                .translate_count = 7,
            },
            .{
                .bone_idx = 2, // Head
                .rotates = [_]Rotate{
                    Rotate.init(0, 0),
                    Rotate.init(0.1333, 33.97), //"curve": "stepped"  TODO ??
                    Rotate.init(0.2333, 33.97),
                    Rotate.init(0.3, 45.52),
                    Rotate.init(0.3667, 24.64),
                    Rotate.init(0.4333, 12.6),
                    Rotate.init(0.5667, 24.64),
                    Rotate.init(1, 24.64),
                } ++ [_]Rotate{.empty} ** 8,
                .rotate_count = 8,
            },
            .{
                .bone_idx = 1, // Body
                .rotates = [_]Rotate{
                    Rotate.init(0, 0),
                    Rotate.init(0.1333, -19.28),
                    Rotate.init(0.3667, -89.57),
                    Rotate.init(0.4333, -85.6),
                    Rotate.init(0.5667, -89.57),
                    Rotate.init(1, -89.57),
                } ++ [_]Rotate{.empty} ** 10,
                .rotate_count = 6,
                .translates = [_]Translate{
                    Translate.init(0, 0, 0),
                    Translate.init(0.2333, 0, -179.14),
                    Translate.init(0.3667, 0, -54.74),
                    Translate.init(1, 0, -54.74),
                } ++ [_]Translate{.empty} ** 12,
                .translate_count = 4,
            },
        } ++ [_]BoneAnimation{.empty} ** 10,
    };

    const attack: Animation = .{
        .name = "attack",
        .duration = 2,
        .bone_animation_count = 5,
        .bone_animations = [_]BoneAnimation{
            .{
                .bone_idx = 3,
                .rotates = [_]Rotate{
                    Rotate.init(0, 0),
                    Rotate.init(0.4667, -45.89),
                    Rotate.init(0.8667, 0),
                    Rotate.init(1, 0),
                } ++ [_]Rotate{.empty} ** 12,
                .rotate_count = 4,
                .translates = [_]Translate{
                    Translate.init(0, 0, 0),
                    Translate.init(0.3333, 490.2, -94.59),
                    Translate.init(0.4667, 189.18, 537.82),
                    Translate.init(0.6333, 317.91, -27),
                    Translate.init(0.8667, 0, 0),
                    Translate.init(1, 0, 0),
                } ++ [_]Translate{.empty} ** 10,
                .translate_count = 6,
            },
            .{
                .bone_idx = 6,
                .translates = [_]Translate{
                    Translate.init(0, 0, 2.49),
                    Translate.init(0.8667, 0, 0),
                    Translate.init(1, 0, 0),
                } ++ [_]Translate{.empty} ** 13,
                .translate_count = 3,
            },
            .{
                .bone_idx = 4, // R_Hand
                .translates = [_]Translate{
                    Translate.init(0, 0, 0),
                    Translate.init(0.3333, 72.48, 82.94),
                    Translate.init(0.4667, 242.75, -342.29),
                    Translate.init(0.6333, 93.61, 77.41),
                    Translate.init(0.8667, 0, 0),
                    Translate.init(1, 0, 0),
                } ++ [_]Translate{.empty} ** 10,
                .translate_count = 6,
            },
            .{
                .bone_idx = 1, // Body
                .rotates = [_]Rotate{
                    Rotate.init(0, 0),
                    Rotate.init(0.3333, -8.67),
                    Rotate.init(0.4667, 12.43),
                    Rotate.init(0.8667, 0),
                    Rotate.init(1, 0),
                } ++ [_]Rotate{.empty} ** 11,
                .rotate_count = 5,
            },
            .{
                .bone_idx = 2,
                .rotates = [_]Rotate{
                    Rotate.init(0, 0),
                    Rotate.init(0.3333, 11.9),
                    Rotate.init(0.4667, -9.85),
                    Rotate.init(0.8667, 0),
                    Rotate.init(1, 0),
                } ++ [_]Rotate{.empty} ** 11,
                .rotate_count = 5,
            },
        } ++ [_]BoneAnimation{.empty} ** 11,
    };

    const jump: Animation = .{
        .name = "jump",
        .duration = 2,
        .bone_animation_count = 6,
        .bone_animations = [_]BoneAnimation{
            .{
                .bone_idx = 2,
                .rotates = [_]Rotate{
                    Rotate.init(0, 4.69),
                    Rotate.init(0.3333, 7.05),
                    Rotate.init(0.6667, 4.69),
                    Rotate.init(1, 4.69),
                } ++ [_]Rotate{.empty} ** 12,
                .rotate_count = 4,
            },
            .{
                .bone_idx = 3,
                .translates = [_]Translate{
                    Translate.init(0, 576.23, -96.93),
                    Translate.init(0.3333, 535.03, -96.49),
                    Translate.init(0.6667, 576.23, -86.93),
                    Translate.init(1, 576.23, -86.93),
                } ++ [_]Translate{.empty} ** 12,
                .translate_count = 4,
            },
            .{
                .bone_idx = 4,
                .translates = [_]Translate{
                    Translate.init(0, 640.51, 85.75),
                    Translate.init(0.3333, 584.77, 72.81),
                    Translate.init(0.6667, 640.51, 85.75),
                    Translate.init(1, 640.51, 85.75),
                } ++ [_]Translate{.empty} ** 12,
                .translate_count = 4,
            },
            .{
                .bone_idx = 1,
                .rotates = [_]Rotate{
                    Rotate.init(0, -6.9),
                    Rotate.init(1, -6.9),
                } ++ [_]Rotate{.empty} ** 14,
                .rotate_count = 2,
                .translates = [_]Translate{
                    Translate.init(0, 8.66, 55.03),
                    Translate.init(1, 8.66, 55.03),
                } ++ [_]Translate{.empty} ** 14,
                .translate_count = 2,
            },
            .{
                .bone_idx = 5,
                .rotates = [_]Rotate{
                    Rotate.init(0, 32.02),
                    Rotate.init(0.3333, 46.74),
                    Rotate.init(0.6667, 32.02),
                    Rotate.init(1, 32.02),
                } ++ [_]Rotate{.empty} ** 12,
                .rotate_count = 4,
            },
            .{
                .bone_idx = 6,
                .rotates = [_]Rotate{
                    Rotate.init(0, 25.02),
                    Rotate.init(0.3333, 33.22),
                    Rotate.init(0.6667, 25.02),
                    Rotate.init(1, 25.02),
                } ++ [_]Rotate{.empty} ** 12,
                .rotate_count = 4,
            },
        } ++ [_]BoneAnimation{.empty} ** 10,
    };

    const idle: Animation = .{
        .name = "idle",
        .duration = 1,
        .bone_animation_count = 5,
        .bone_animations = [_]BoneAnimation{
            .{
                .bone_idx = 2,
                .translates = [_]Translate{
                    Translate.init(0, 0, 0),
                    Translate.init(0.2, -9.68, 1.05),
                    Translate.init(0.6666, 21.57, 2.33),
                    Translate.init(1, 0, 0),
                } ++ [_]Translate{.empty} ** 12,
                .translate_count = 4,
            },
            .{
                .bone_idx = 6,
                .translates = [_]Translate{
                    Translate.init(0, -3.68, 5.5),
                    Translate.init(1, -3.68, 5.5),
                } ++ [_]Translate{.empty} ** 14,
                .translate_count = 2,
            },
            .{
                .bone_idx = 4,
                .translates = [_]Translate{
                    Translate.init(0, 0, 0),
                    Translate.init(0.1667, -12.37, -1.34),
                    Translate.init(0.5, 0, 0),
                    Translate.init(0.7333, 9.89, 1.07),
                    Translate.init(1, 0, 0),
                } ++ [_]Translate{.empty} ** 11,
                .translate_count = 5,
            },
            .{
                .bone_idx = 3,
                .translates = [_]Translate{
                    Translate.init(0, 0, 0),
                    Translate.init(0.1667, -12.37, -1.34),
                    Translate.init(0.5, 0, 0),
                    Translate.init(0.7333, 9.89, 1.07),
                    Translate.init(1, 0, 0),
                } ++ [_]Translate{.empty} ** 11,
                .translate_count = 5,
            },
        } ++ [_]BoneAnimation{.empty} ** 12,
    };
};

const BoneAnimation = struct {
    bone_idx: usize = 0,
    translates: [16]Translate = [_]Translate{.empty} ** 16,
    translate_count: usize = 0,
    rotates: [16]Rotate = [_]Rotate{.empty} ** 16,
    rotate_count: usize = 0,

    const empty: BoneAnimation = .{};
};

const Rotate = struct {
    t: f32,
    v: f32,

    const empty: Rotate = .{ .t = 0, .v = 0 };

    fn init(
        t: f32,
        v: f32,
    ) Rotate {
        return .{
            .t = t,
            .v = v,
        };
    }
};

const Translate = struct {
    t: f32,
    x: f32,
    y: f32,

    const empty: Translate = .{ .t = 0, .x = 0, .y = 0 };

    fn init(
        t: f32,
        x: f32,
        y: f32,
    ) Translate {
        return .{
            .t = t,
            .x = x,
            .y = y,
        };
    }
};

fn lerp(from: f32, to: f32, percent: f32) f32 {
    return from + (to - from) * percent;
}

fn slerp(from: f32, to: f32, percent: f32) f32 {
    const sp = @sin((percent - 0.5) * std.math.pi / 2);
    return lerp(from, to, sp);
}

fn text_color(i: usize) raylib.struct_Color {
    if (g_state.skeleton.animation_playing_idx == i) {
        return raylib.RED;
    }
    return raylib.WHITE;
}

var g_state: *State = undefined;

fn init(alloc: *anyopaque) callconv(.c) void {
    raylib.TraceLog(raylib.LOG_INFO, "plugin init");
    const allocator: *std.mem.Allocator = @ptrCast(@alignCast(alloc));
    g_state = State.create(allocator.*) catch unreachable;
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
}

fn update() callconv(.c) void {
    raylib.ClearBackground(.{ .r = 0x40, .g = 0x40, .b = 0x40, .a = 0xFF });

    raylib.DrawText("Animation:", 10, 10, 28, raylib.WHITE);
    raylib.DrawText("[I]dle", 10, 40, 28, text_color(0));
    raylib.DrawText("[J]ump", 10, 70, 28, text_color(1));
    raylib.DrawText("[A]ttack", 10, 100, 28, text_color(2));
    raylib.DrawText("[D]eath", 10, 130, 28, text_color(3));

    if (raylib.IsKeyPressed(raylib.KEY_I)) {
        g_state.skeleton.anime(0);
    }
    if (raylib.IsKeyPressed(raylib.KEY_J)) {
        g_state.skeleton.anime(1);
    }
    if (raylib.IsKeyPressed(raylib.KEY_A)) {
        g_state.skeleton.anime(2);
    }
    if (raylib.IsKeyPressed(raylib.KEY_D)) {
        g_state.skeleton.anime(3);
    }
    g_state.skeleton.draw();
}

export const api: PluginApi = .{
    .init = init,
    .deinit = deinit,
    .pre_reload = pre_reload,
    .post_reload = post_reload,
    .update = update,
};
