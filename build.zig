const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("zregex", .{
        .root_source_file = b.path("root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const c_source_files_options = std.Build.Module.AddCSourceFilesOptions{
        .files = &[_][]const u8{"adapter.c"},
    };
    const c_include_path = std.Build.LazyPath{
        .src_path = .{
            .owner = b,
            .sub_path = ".",
        },
    };

    module.addIncludePath(c_include_path);
    module.addCSourceFiles(c_source_files_options);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("root.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib_unit_tests.addIncludePath(c_include_path);
    lib_unit_tests.addCSourceFiles(c_source_files_options);
    lib_unit_tests.linkLibC();

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
