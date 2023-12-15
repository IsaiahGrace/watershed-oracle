const std = @import("std");
const raylib = @import("lib/raylib/build.zig");

// We're going to be compiling 4 binaries
// 1. watershedCoreNative -> A simple stdin->stdout text based lookup algorithm
// 2. watershedGuiNative  -> A simulation of the beepy screen
// 3. watershedCoreArm    -> A cross-compiled version of the core lookup algorithm
// 4. watershedGuiArm     -> The "real" beepy application. Drives the screen using raylib in framebuffer mode.

const armTargetTriplet = "arm-linux-gnueabihf";
const armCpuFeatures = "cortex_a53";

fn addWatershedCoreNative(
    b: *std.Build,
    target: std.zig.CrossTarget,
    optimize: std.builtin.OptimizeMode,
) !*std.Build.CompileStep {
    const watershedCoreNative = b.addExecutable(.{
        .name = "watershedCoreNative",
        .root_source_file = .{ .path = "src/mainCore.zig" },
        .target = target,
        .optimize = optimize,
    });
    watershedCoreNative.linkLibC();
    watershedCoreNative.linkSystemLibrary("geos_c");
    watershedCoreNative.linkSystemLibrary("sqlite3");
    return watershedCoreNative;
}

fn addWatershedGuiNative(
    b: *std.Build,
    target: std.zig.CrossTarget,
    optimize: std.builtin.OptimizeMode,
) !*std.Build.CompileStep {
    const watershedGuiNative = b.addExecutable(.{
        .name = "watershedGuiNative",
        .root_source_file = .{ .path = "src/mainGui.zig" },
        .target = target,
        .optimize = optimize,
    });
    watershedGuiNative.linkLibC();
    watershedGuiNative.linkSystemLibrary("geos_c");
    watershedGuiNative.linkSystemLibrary("sqlite3");
    watershedGuiNative.addIncludePath(.{ .path = "lib/raylib" });
    return watershedGuiNative;
}

fn addWatershedCoreArm(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
) !*std.Build.CompileStep {
    const target = try std.zig.CrossTarget.parse(.{
        .arch_os_abi = armTargetTriplet,
        .cpu_features = armCpuFeatures,
    });
    const watershedCoreArm = b.addExecutable(.{
        .name = "watershedCoreArm",
        .root_source_file = .{ .path = "src/mainCore.zig" },
        .target = target,
        .optimize = optimize,
    });
    watershedCoreArm.addIncludePath(.{ .path = "lib/arm-linux-gnueabihf/inc" });
    watershedCoreArm.addIncludePath(.{ .path = "lib/arm-linux-gnueabihf/inc/arm-linux-gnueabihf" });
    watershedCoreArm.addLibraryPath(.{ .path = "lib/arm-linux-gnueabihf/lib" });
    watershedCoreArm.linkLibC();
    watershedCoreArm.linkSystemLibrary("geos_c");
    watershedCoreArm.linkSystemLibrary("sqlite3");
    return watershedCoreArm;
}

fn addWatershedGuiArm(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
) !*std.Build.CompileStep {
    const target = try std.zig.CrossTarget.parse(.{
        .arch_os_abi = armTargetTriplet,
        .cpu_features = armCpuFeatures,
    });
    const watershedGuiArm = b.addExecutable(.{
        .name = "watershedGuiArm",
        .root_source_file = .{ .path = "src/mainGui.zig" },
        .target = target,
        .optimize = optimize,
    });
    watershedGuiArm.addIncludePath(.{ .path = "lib/arm-linux-gnueabihf/inc" });
    watershedGuiArm.addIncludePath(.{ .path = "lib/arm-linux-gnueabihf/inc/arm-linux-gnueabihf" });
    watershedGuiArm.addIncludePath(.{ .path = "lib/raylib" });
    watershedGuiArm.addLibraryPath(.{ .path = "lib/arm-linux-gnueabihf/lib" });
    watershedGuiArm.linkLibC();
    watershedGuiArm.linkSystemLibrary("geos_c");
    watershedGuiArm.linkSystemLibrary("sqlite3");
    return watershedGuiArm;
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

    const optionsGui = b.addOptions();
    optionsGui.addOption(bool, "gui", true);

    const optionsCore = b.addOptions();
    optionsCore.addOption(bool, "gui", false);

    // This "clap" refers to the .clap field in the build.zig.zon file
    const clapNative = b.dependency("clap", .{
        .target = target,
        .optimize = optimize,
    });

    const clapArm = b.dependency("clap", .{
        .target = target,
        .optimize = targetArm,
    });

    const rlibNative = raylib.addRaylib(b, target, optimize, .{
        .arm = false,
        .platform_drm = false,
        .raudio = false,
        .raygui = false,
        .rmodels = false,
        .rshapes = true,
        .rtext = true,
        .rtextures = true,
    });

    const rlibArm = raylib.addRaylib(b, targetArm, optimize, .{
        .arm = true,
        .platform_drm = true,
        .raudio = false,
        .raygui = false,
        .rmodels = false,
        .rshapes = true,
        .rtext = true,
        .rtextures = true,
    });

    // Add the "Core" binaries, no raylib needed
    const watershedCoreNative = try addWatershedCoreNative(b, target, optimize);
    watershedCoreNative.addModule("clap", clapNative.module("clap"));
    watershedCoreNative.addOptions("config", optionsCore);
    b.installArtifact(watershedCoreNative);

    const watershedCoreArm = try addWatershedCoreArm(b, optimize);
    watershedCoreArm.addModule("clap", clapArm.module("clap"));
    watershedCoreArm.addOptions("config", optionsCore);
    b.installArtifact(watershedCoreArm);

    // Add the "Gui" binaries, with raylib linked and included
    const watershedGuiNative = try addWatershedGuiNative(b, target, optimize);
    watershedGuiNative.addModule("clap", clapNative.module("clap"));
    watershedGuiNative.addOptions("config", optionsGui);
    watershedGuiNative.linkLibrary(rlibNative);
    b.installArtifact(watershedGuiNative);

    const watershedGuiArm = try addWatershedGuiArm(b, optimize);
    watershedGuiArm.addModule("clap", clapArm.module("clap"));
    watershedGuiArm.addOptions("config", optionsGui);
    watershedGuiArm.linkLibrary(rlibArm);
    b.installArtifact(watershedGuiArm);

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
    const core_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/mainCore.zig" },
        .target = target,
        .optimize = optimize,
    });
    core_tests.addModule("clap", clapNative.module("clap"));
    core_tests.linkLibC();
    core_tests.linkSystemLibrary("geos_c");
    core_tests.linkSystemLibrary("sqlite3");
    core_tests.addIncludePath(.{ .path = "lib/raylib" });
    core_tests.linkLibrary(rlibNative);
    const run_core_tests = b.addRunArtifact(core_tests);

    const gui_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/mainGui.zig" },
        .target = target,
        .optimize = optimize,
    });
    gui_tests.addModule("clap", clapNative.module("clap"));
    gui_tests.linkLibC();
    gui_tests.linkSystemLibrary("geos_c");
    gui_tests.linkSystemLibrary("sqlite3");
    gui_tests.addIncludePath(.{ .path = "lib/raylib" });
    gui_tests.linkLibrary(rlibNative);
    const run_gui_tests = b.addRunArtifact(gui_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_core_tests.step);
    test_step.dependOn(&run_gui_tests.step);
}
