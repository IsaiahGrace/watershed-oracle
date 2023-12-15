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

    const framebuffer = b.option(bool, "framebuffer", "Compile with framebuffer support (Beepy hardware only)") orelse false;

    // From lib/raylib/build.zig
    const raylibOptions = raylib.Options{
        .platform_drm = framebuffer,
        .raudio = false,
        .rmodels = false,
        .rtext = true,
        .rtextures = true,
        .rshapes = true,
        .raygui = false,
    };
    const rlib = raylib.addRaylib(b, target, optimize, raylibOptions);

    // This "clap" refers to the .clap field in the build.zig.zon file
    const clap = b.dependency("clap", .{
        .target = target,
        .optimize = optimize,
    });

    // watershedBeepy is a full app intended to run on the Beepy. It drives the 400x240 display using raylib.
    const beepy = b.addExecutable(.{
        .name = "watershedBeepy",
        .root_source_file = .{ .path = "src/beepyMain.zig" },
        .target = target,
        .optimize = optimize,
    });
    beepy.addModule("clap", clap.module("clap"));
    beepy.linkLibC();
    beepy.linkSystemLibrary("geos_c");
    beepy.linkSystemLibrary("sqlite3");
    beepy.addIncludePath(.{ .path = "lib/raylib" });
    beepy.linkLibrary(rlib);
    b.installArtifact(beepy);

    // watershedCore is just the lookup engine, reading WKT point data from stdin, and printing watershed data to stdout.
    const core = b.addExecutable(.{
        .name = "watershedCore",
        .root_source_file = .{ .path = "src/coreMain.zig" },
        .target = target,
        .optimize = optimize,
    });
    core.addModule("clap", clap.module("clap"));
    core.linkLibC();
    core.linkSystemLibrary("geos_c");
    core.linkSystemLibrary("sqlite3");
    core.addIncludePath(.{ .path = "lib/raylib" });
    core.linkLibrary(rlib);
    b.installArtifact(core);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(core);

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
    const core_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/coreMain.zig" },
        .target = target,
        .optimize = optimize,
    });
    core_tests.addModule("clap", clap.module("clap"));
    core_tests.linkLibC();
    core_tests.linkSystemLibrary("geos_c");
    core_tests.linkSystemLibrary("sqlite3");
    core_tests.addIncludePath(.{ .path = "lib/raylib" });
    core_tests.linkLibrary(rlib);
    const run_core_tests = b.addRunArtifact(core_tests);

    const beepy_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/beepyMain.zig" },
        .target = target,
        .optimize = optimize,
    });
    beepy_tests.addModule("clap", clap.module("clap"));
    beepy_tests.linkLibC();
    beepy_tests.linkSystemLibrary("geos_c");
    beepy_tests.linkSystemLibrary("sqlite3");
    beepy_tests.addIncludePath(.{ .path = "lib/raylib" });
    beepy_tests.linkLibrary(rlib);
    const run_beepy_tests = b.addRunArtifact(beepy_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_core_tests.step);
    test_step.dependOn(&run_beepy_tests.step);
}
