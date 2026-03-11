const std = @import("std");

pub const Api = extern struct {
    init: *const fn (*anyopaque) callconv(.c) void,
    deinit: *const fn () callconv(.c) void,
    pre_reload: *const fn () callconv(.c) *anyopaque,
    post_reload: *const fn (*anyopaque) callconv(.c) void,
    update: *const fn () callconv(.c) void,
};

pub const Plugin = struct {
    path: []const u8,
    lib: std.DynLib,
    api: *const Api,
    inode: std.c.ino_t,

    pub fn init(allocator: std.mem.Allocator, path: []const u8) !Plugin {
        const f = try std.fs.cwd().openFile(path, .{});
        defer f.close();
        const stat = try f.stat();

        var lib = try std.DynLib.open(path);
        const api = lib.lookup(*const Api, "api").?;

        api.init(@ptrCast(@constCast(&allocator)));

        return .{
            .path = path,
            .lib = lib,
            .api = api,
            .inode = stat.inode,
        };
    }

    pub fn deinit(self: *Plugin) void {
        self.api.deinit();
        self.lib.close();
    }

    pub fn maybe_reload(self: *Plugin) !void {
        const f = try std.fs.cwd().openFile(self.path, .{});
        defer f.close();
        const stat = try f.stat();

        if (stat.inode != self.inode) {
            const state = self.api.pre_reload();

            self.lib.close();

            var new_lib = try std.DynLib.open(self.path);
            self.lib = new_lib;
            self.api = new_lib.lookup(*const Api, "api").?;
            self.inode = stat.inode;

            self.api.post_reload(state);
        }
    }

    pub fn update(self: *Plugin) void {
        self.api.update();
    }
};
