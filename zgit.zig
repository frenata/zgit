const std = @import("std");
const warn = std.debug.warn;
const Dir = std.fs.Dir;

//const alloc = std.heap.page_allocator;
const alloc = std.testing.allocator;

const NotAGitRepoError = error{FileNotFound};

pub fn initializeRepo(path: []const u8) !Dir {
    var cwd = std.fs.cwd();
    try cwd.makeDir(path);
    var tree = try cwd.openDir(path, .{ .access_sub_paths = true, .iterate = true });
    try tree.makeDir(".git");

    warn("new repo initialized: {}\n", .{path});

    return tree;
}

pub fn getRepo(path: []const u8) !Dir {
    var cwd = std.fs.cwd();
    // refactor so these functions are called separately in the caller
    var tree = cwd.openDir(path, .{ .access_sub_paths = true, .iterate = true }) catch |e| {
        return try initializeRepo(path);
    };

    tree.access(".git", .{ .read = true }) catch |e| {
        std.debug.panic("dir exists but not a git repo: {}", .{path});
    };

    return tree;
}

const Repo = struct {
    tree: Dir,

    pub fn init(path: []const u8) !*Repo {
        var work = try getRepo(path);

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

pub fn main() void {
    var args = std.process.args().inner;
    _ = args.next(); // throw away binary name
    if (args.next()) |command| {
        warn("command: {}\n", .{command});
        if (std.mem.eql(u8, command, "init")) {
            init(args.next());
        }
    } else {
        warn("TODO print help\n", .{});
    }
}
