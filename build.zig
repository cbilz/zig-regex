const Build = @import("std").Build;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("regex", .{
        .source_file = .{ .path = "src/regex.zig" },
    });

    // library tests
    const library_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/all_test.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_library_tests = b.addRunArtifact(library_tests);

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_library_tests.step);

    // C library
    const staticLib = b.addStaticLibrary(.{
        .name = "regex",
        .root_source_file = .{ .path = "src/c_regex.zig" },
        .target = target,
        .optimize = optimize,
    });
    staticLib.linkLibC();
    staticLib.installHeadersDirectory("include", "");

    b.installArtifact(staticLib);

    const sharedLib = b.addSharedLibrary(.{
        .name = "regex",
        .root_source_file = .{ .path = "src/c_regex.zig" },
        .target = target,
        .optimize = optimize,
    });
    sharedLib.linkLibC();
    sharedLib.installHeadersDirectory("include", "");

    b.installArtifact(sharedLib);

    // C example
    const c_example = b.addExecutable(.{
        .name = "example",
        .target = target,
        .optimize = optimize,
    });
    c_example.addCSourceFile(.{ .file = .{ .path = "example/example.c" }, .flags = &.{} });
    c_example.linkLibC();
    c_example.linkLibrary(staticLib);
    const c_example_install = b.addInstallArtifact(c_example, .{});

    const c_example_step = b.step("c-example", "Example using C API");
    c_example_step.dependOn(&c_example_install.step);

    b.default_step.dependOn(test_step);
}
