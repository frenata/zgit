const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("zgit", "src/zgit.zig");
    exe.setBuildMode(mode);
    exe.setOutputDir("bin");
    b.default_step.dependOn(&exe.step);
}
