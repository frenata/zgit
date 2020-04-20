const std = @import("std");
const warn = std.debug.warn;
const Dir = std.fs.Dir;

const alloc = std.testing.allocator;

const NotAGitRepoError = error{FileNotFound};

pub fn initializeRepo(path: []const u8) !Dir {
    var cwd = std.fs.cwd();
    cwd.makeDir(path) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    var tree = try cwd.openDir(path, .{ .access_sub_paths = true, .iterate = true });
    try tree.makeDir(".git");

    warn("new repo initialized: {}\n", .{path});
    return tree;
}

pub fn getRepo(cwd: Dir, path: []const u8) !Dir {
    // refactor so these functions are called separately in the caller
    var tree = try cwd.openDir(path, .{ .access_sub_paths = true, .iterate = true });

    tree.access(".git", .{ .read = true }) catch |e| {
        return error.NotAGitRepo;
    };

    return tree;
}

const Repo = struct {
    tree: Dir,

    pub fn init(path: []const u8) !*Repo {
        var cwd = std.fs.cwd();
        var work = getRepo(cwd, path) catch |err| switch (err) {
            error.FileNotFound => try initializeRepo(path),
            else => return err,
        };

        var repo = try alloc.create(Repo);
        repo.* = Repo{
            .tree = work,
        };
        std.debug.warn("worktree: {}\n", .{repo.tree});
        return repo;
    }
};

pub fn init(path: ?[]const u8) void {
    const clone = path orelse ".";
    warn("cloning: {}\n", .{clone});
    var repo = Repo.init(clone);
}

pub fn status() !void {
    var cwd = std.fs.cwd();
    while (true) {
        var repo = getRepo(cwd, ".") catch |err| switch (err) {
            error.NotAGitRepo => {
                cwd = try cwd.openDir("..", .{ .access_sub_paths = true });
                continue;
            },
            else => return err,
        };
        std.debug.warn("repo: {}", .{repo});
        return;
    }
}

pub fn main() void {
    var args = std.process.args().inner;
    _ = args.next(); // throw away binary name
    if (args.next()) |command| {
        warn("command: {}\n", .{command});
        if (std.mem.eql(u8, command, "init")) {
            init(args.next());
        } else if (std.mem.eql(u8, command, "status")) {
            var f = status();
        }
    } else {
        warn("TODO print help\n", .{});
    }
}
