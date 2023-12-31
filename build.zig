const std = @import("std");
const raylib = @import("lib/raylib/build.zig");

// We're going to be compiling 4 binaries
// 1. watershedOracle   -> A simple stdin->stdout text based lookup algorithm
// 2. watershedGuiSim   -> A simulation of the beepy screen
// 3. arm-watershedCore -> A cross-compiled version of the core lookup algorithm
// 4. arm-watershedGui  -> The "real" beepy application. Drives the screen using raylib in framebuffer mode.

const armTargetTriplet = "arm-linux-gnueabihf";
const armCpuFeatures = "cortex_a53";

const PointProviders = enum {
    fuzzer,
    gps,
    scatter,
    stdin,
};

const DisplayMode = enum {
    none,
    windowed,
    framebuffer,
};

fn addWatershedExe(
    b: *std.Build,
    binaryName: []const u8,
    target: std.zig.CrossTarget,
    optimize: std.builtin.OptimizeMode,
    pointProvider: PointProviders,
    displayMode: DisplayMode,
) !*std.Build.CompileStep {
    const exe = b.addExecutable(.{
        .name = binaryName,
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    if (target.getCpuArch() == .arm) {
        exe.addIncludePath(.{ .path = "lib/arm-linux-gnueabihf/inc" });
        exe.addIncludePath(.{ .path = "lib/arm-linux-gnueabihf/inc/arm-linux-gnueabihf" });
        exe.addLibraryPath(.{ .path = "lib/arm-linux-gnueabihf/lib" });
    }

    if (displayMode != .none) {
        exe.addIncludePath(.{ .path = "lib/raylib" });
    }

    exe.linkLibC();
    exe.linkSystemLibrary("geos_c");
    exe.linkSystemLibrary("sqlite3");

    const clap = b.dependency("clap", .{
        .target = target,
        .optimize = optimize,
    });
    exe.addModule("clap", clap.module("clap"));

    const options = b.addOptions();
    options.addOption(DisplayMode, "displayMode", displayMode);
    options.addOption(PointProviders, "pointProvider", pointProvider);
    exe.addOptions("config", options);

    if (displayMode != .none) {
        exe.linkLibrary(
            raylib.addRaylib(b, target, optimize, .{
                .arm = if (target.getCpuArch() == .arm) true else false,
                .platform_drm = if (displayMode == .framebuffer) true else false,
                .raudio = false,
                .raygui = false,
                .rmodels = false,
                .rshapes = true,
                .rtext = true,
                .rtextures = true,
            }),
        );
    }
    b.installArtifact(exe);
    return exe;
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    const targetArm = try std.zig.CrossTarget.parse(.{
        .arch_os_abi = armTargetTriplet,
        .cpu_features = armCpuFeatures,
    });

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const clap = b.dependency("clap", .{
        .target = target,
        .optimize = optimize,
    });
    const options = b.addOptions();
    options.addOption(DisplayMode, "displayMode", .none);
    options.addOption(PointProviders, "pointProvider", .stdin);

    const watershedCoreNative = try addWatershedExe(b, "watershedOracle", target, optimize, .stdin, .none);
    _ = try addWatershedExe(b, "watershedGuiSim", target, optimize, .stdin, .windowed);
    _ = try addWatershedExe(b, "arm-watershedCore", targetArm, optimize, .stdin, .none);
    _ = try addWatershedExe(b, "arm-watershedGui", targetArm, optimize, .stdin, .framebuffer);
    _ = try addWatershedExe(b, "watershedFuzzer", target, optimize, .fuzzer, .none);

    const pathUtil = b.addExecutable(.{
        .name = "pathUtil",
        .root_source_file = .{ .path = "src/pathUtil.zig" },
        .target = target,
        .optimize = optimize,
    });
    pathUtil.addModule("clap", clap.module("clap"));
    pathUtil.addOptions("config", options);
    b.installArtifact(pathUtil);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(watershedCoreNative);

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

    // Because we have two top level files, we'll compile two sets of unit tests
    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    tests.addModule("clap", clap.module("clap"));
    tests.linkLibC();
    tests.linkSystemLibrary("geos_c");
    tests.linkSystemLibrary("sqlite3");
    tests.addIncludePath(.{ .path = "lib/raylib" });
    tests.linkLibrary(
        raylib.addRaylib(b, target, optimize, .{
            .arm = false,
            .platform_drm = false,
            .raudio = false,
            .raygui = false,
            .rmodels = false,
            .rshapes = true,
            .rtext = true,
            .rtextures = true,
        }),
    );
    tests.addOptions("config", options);

    const run_core_tests = b.addRunArtifact(tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_core_tests.step);
}
