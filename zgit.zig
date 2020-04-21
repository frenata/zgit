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

pub fn getRepo(cwd: Dir, path: []const u8) ?Dir {
    // refactor so these functions are called separately in the caller
    var tree = cwd.openDir(path, .{ .access_sub_paths = true, .iterate = true }) catch return null;
    tree.access(".git", .{ .read = true }) catch return null;
    return tree;
}

const Repo = struct {
    tree: Dir,

    pub fn init(cwd: Dir) !*Repo {
        var work = getRepo(cwd, ".") orelse return error.NotAGitRepo;

        var repo = try alloc.create(Repo);
        repo.* = Repo{
            .tree = work,
        };
        std.debug.warn("worktree: {}\n", .{repo.tree});
        return repo;
    }
};

pub fn cmdInit(path: ?[]const u8) !void {
    const clone = path orelse ".";
    warn("cloning: {}\n", .{clone});
    var tree = try initializeRepo(clone);
    var repo = Repo.init(tree);
}

pub fn cmdStatus() !void {
    var cwd = std.fs.cwd();
    cwd = try cwd.openDir(".", .{});
    warn("cwd fd: {}\n", .{cwd.fd});
    while (true) {
        warn("iterate upwards\n", .{});
        if (getRepo(cwd, ".")) |dir| {
            std.debug.warn("repo: {}", .{Repo.init(dir)});
            return;
        } else {
            var nwd = cwd.openDir("..", .{ .access_sub_paths = true }) catch |err| {
                warn("err: {}", .{err});
                return err;
            };
            var nwd_stat = try std.os.fstat(nwd.fd);
            var cwd_stat = try std.os.fstat(cwd.fd);
            warn("inodes: {} {}\n", .{ cwd_stat.ino, nwd_stat.ino });
            if (nwd_stat.ino == cwd_stat.ino) {
                warn("hit the root: {}", .{cwd_stat.ino});
                return error.NotAGitRepo;
            }
            cwd = nwd;
            continue;
        }
    }
}

pub fn main() void {
    var args = std.process.args().inner;
    _ = args.next(); // throw away binary name
    if (args.next()) |command| {
        warn("command: {}\n", .{command});
        if (std.mem.eql(u8, command, "init")) {
            warn("{}", .{cmdInit(args.next())});
        } else if (std.mem.eql(u8, command, "status")) {
            warn("{}", .{cmdStatus()});
        }
    } else {
        warn("TODO print help\n", .{});
    }
}
