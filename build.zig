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
    clap: *std.build.Dependency,
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
        exe.linkSystemLibrary("pigpiod_if2");
    }

    if (displayMode != .none) {
        exe.addIncludePath(.{ .path = "lib/raylib" });
    }

    exe.linkLibC();
    exe.linkSystemLibrary("geos_c");
    exe.linkSystemLibrary("sqlite3");
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

fn addPathUtilExe(
    b: *std.Build,
    binaryName: []const u8,
    target: std.zig.CrossTarget,
    optimize: std.builtin.OptimizeMode,
    clap: *std.build.Dependency,
) !*std.Build.CompileStep {
    const options = b.addOptions();
    options.addOption(DisplayMode, "displayMode", .none);
    options.addOption(PointProviders, "pointProvider", .stdin);

    const pathUtil = b.addExecutable(.{
        .name = binaryName,
        .root_source_file = .{ .path = "src/pathUtil.zig" },
        .target = target,
        .optimize = optimize,
    });

    if (target.getCpuArch() == .arm) {
        pathUtil.addIncludePath(.{ .path = "lib/arm-linux-gnueabihf/inc" });
        pathUtil.addIncludePath(.{ .path = "lib/arm-linux-gnueabihf/inc/arm-linux-gnueabihf" });
        pathUtil.addLibraryPath(.{ .path = "lib/arm-linux-gnueabihf/lib" });
        pathUtil.linkLibC();
        pathUtil.linkSystemLibrary("pigpiod_if2");
    }

    pathUtil.addModule("clap", clap.module("clap"));
    pathUtil.addOptions("config", options);
    b.installArtifact(pathUtil);
    return pathUtil;
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

    const clap = b.dependency("clap", .{ .target = target, .optimize = optimize });
    const clapArm = b.dependency("clap", .{ .target = targetArm, .optimize = optimize });

    _ = try addWatershedExe(b, "arm-watershedCore", targetArm, optimize, clapArm, .stdin, .none);
    _ = try addWatershedExe(b, "arm-watershedGui", targetArm, optimize, clapArm, .stdin, .framebuffer);

    _ = try addWatershedExe(b, "watershedOracle", target, optimize, clap, .stdin, .none);
    _ = try addWatershedExe(b, "watershedFuzzer", target, optimize, clap, .fuzzer, .none);
    _ = try addWatershedExe(b, "watershedGuiSim", target, optimize, clap, .stdin, .windowed);
    _ = try addWatershedExe(b, "watershedGPSMock", target, optimize, clap, .gps, .none);

    _ = try addPathUtilExe(b, "arm-pathUtil", targetArm, optimize, clapArm);
    _ = try addPathUtilExe(b, "pathUtil", target, optimize, clap);

    // TESTS:

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
    const options = b.addOptions();
    options.addOption(DisplayMode, "displayMode", .none);
    options.addOption(PointProviders, "pointProvider", .stdin);
    tests.addOptions("config", options);

    const run_core_tests = b.addRunArtifact(tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_core_tests.step);
}
