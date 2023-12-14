const std = @import("std");
const raylib = @import("lib/raylib/build.zig");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const beepyMode = b.option(bool, "beepyMode", "Compile with Beepy specific features") orelse false;

    // From lib/raylib/build.zig
    const raylibOptions = raylib.Options{
        .platform_drm = beepyMode,
        .raudio = false,
        .rmodels = false,
        .rtext = true,
        .rtextures = true,
        .rshapes = true,
        .raygui = false,
    };
    const rlib = raylib.addRaylib(b, target, optimize, raylibOptions);
    b.installArtifact(rlib);

    // This "clap" refers to the .clap field in the build.zig.zon file
    const clap = b.dependency("clap", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "watershedOracle",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    // The first "clap" refers to build.zig.zon, the second "clap" refers to the b.addModule("clap", ...) call in the zig-clap build.zig file.
    exe.addModule("clap", clap.module("clap"));
    exe.linkLibC();
    exe.linkSystemLibrary("geos_c");
    exe.linkSystemLibrary("sqlite3");
    exe.addIncludePath(.{ .path = "lib/raylib" });
    exe.linkLibrary(rlib);
    b.installArtifact(exe);

    const options = b.addOptions();
    options.addOption(bool, "beepyMode", beepyMode);
    exe.addOptions("config", options);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    unit_tests.addModule("clap", clap.module("clap"));
    unit_tests.linkLibC();
    unit_tests.linkSystemLibrary("geos_c");
    unit_tests.linkSystemLibrary("sqlite3");

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
