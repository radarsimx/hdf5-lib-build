#!/bin/bash
# ============================================================================
# build.sh - Build the prebuilt dependencies for RadarSimCpp
#
# Drives the superbuild in this directory, which downloads pinned releases of
# every selected dependency, builds them against a shared ABI baseline and
# stages headers and static libraries into ./output.
#
# Usage:
#   ./build.sh [options]
#
# Arguments:
#   clean     - Force clean build (also removes the staged output directory)
#   debug     - Build in Debug mode (default is Release)
#   hdf5      - Build only HDF5
#   mbedtls   - Build only mbedTLS
#   package   - Also produce release archives and checksums in ./dist
#
# Naming a dependency restricts the build to the ones named; with none named,
# every dependency is built. Arguments may be given in any order.
#
# Examples:
#   ./build.sh                    - Release build of everything
#   ./build.sh mbedtls            - Release build of mbedTLS only
#   ./build.sh clean debug        - Clean Debug build of everything
#   ./build.sh clean package      - Clean build, then archive for a release
#
# Requirements:
#   - bash shell
#   - cmake 3.26 or higher
#   - git (the HDF5 source is cloned at configure time)
#   - network access on the first configure
# ============================================================================

set -euo pipefail
trap 'echo "Error: Command failed at line $LINENO: $BASH_COMMAND" >&2' ERR

# ----------------------
# Variable definitions
# ----------------------
BUILD_DIR="build"              # Directory for CMake build output
OUTPUT_DIR="output"            # Staged headers and libs
DIST_DIR="dist"                # Release archives
BUILD_TYPE="Release"           # Default build type (Release or Debug)
FORCE_CLEAN=0                  # Clean build flag
DO_PACKAGE=0                   # Produce release archives
SELECTED=()                    # Explicitly requested dependencies

# Keep in sync with the recipes/ directory and the superbuild's options.
ALL_DEPS=(hdf5 mbedtls)

# Parse command line arguments
for arg in "$@"; do
    case "$arg" in
        clean)
            FORCE_CLEAN=1
            echo "Force clean build requested"
            ;;
        debug)
            BUILD_TYPE="Debug"
            echo "Debug build requested"
            ;;
        package)
            DO_PACKAGE=1
            echo "Release packaging requested"
            ;;
        hdf5|mbedtls)
            SELECTED+=("$arg")
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: $0 [clean] [debug] [package] [hdf5] [mbedtls]"
            exit 1
            ;;
    esac
done

if [ ${#SELECTED[@]} -eq 0 ]; then
    SELECTED=("${ALL_DEPS[@]}")
fi

echo "Build type:   $BUILD_TYPE"
echo "Dependencies: ${SELECTED[*]}"

# ----------------------
# Check for dependencies
# ----------------------
for cmd in cmake git; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed." >&2
        exit 1
    fi
done

# ----------------------
# Translate the selection into superbuild options
# ----------------------
CMAKE_OPTS=()
for dep in "${ALL_DEPS[@]}"; do
    enabled=OFF
    for sel in "${SELECTED[@]}"; do
        if [ "$sel" = "$dep" ]; then
            enabled=ON
        fi
    done
    # DEPS_BUILD_HDF5 / DEPS_BUILD_MBEDTLS
    CMAKE_OPTS+=("-DDEPS_BUILD_$(echo "$dep" | tr '[:lower:]' '[:upper:]'):BOOL=$enabled")
done

# ----------------------
# Clean previous builds
# ----------------------
echo "## Clean old build files ##"
rm -rf "$BUILD_DIR"

if [ "$FORCE_CLEAN" -eq 1 ]; then
    rm -rf "$OUTPUT_DIR" "$DIST_DIR"
fi

# ----------------------
# Configure and build
# ----------------------
echo "## Building dependencies ##"
cmake -S . -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE:STRING="$BUILD_TYPE" "${CMAKE_OPTS[@]}"
cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" --parallel

# ----------------------
# Package for a GitHub release
# ----------------------
if [ "$DO_PACKAGE" -eq 1 ]; then
    echo "## Packaging release archives ##"
    cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" --target package-release
    echo "Archives and checksums in $DIST_DIR."
fi

# ----------------------
# Completion message
# ----------------------
echo "Build completed successfully. Output in $OUTPUT_DIR."
