#!/bin/bash
# ============================================================================
# build.sh - Build script for HDF5 static libraries
#
# This script drives the CMake project in this directory, which downloads a
# pinned HDF5 release, builds the static C/C++ libraries and stages the
# headers and libraries into the output directory.
#
# Usage:
#   ./build.sh [options]
#
# Arguments:
#   clean   - Force clean build (removes all build artifacts)
#   debug   - Build in Debug mode (default is Release)
#
# Examples:
#   ./build.sh              - Release build
#   ./build.sh debug        - Debug build
#   ./build.sh clean        - Clean Release build
#   ./build.sh clean debug  - Clean Debug build
#
# Requirements:
#   - bash shell
#   - cmake 3.26 or higher
#   - git (the HDF5 source is cloned at configure time)
#   - network access on the first configure
#
# The script will:
#   1. Clean previous build (and, with clean, output) directories
#   2. Configure and build the project using CMake
#   3. Leave the collected headers and static libraries in the output directory
# ============================================================================

set -euo pipefail
trap 'echo "Error: Command failed at line $LINENO: $BASH_COMMAND" >&2' ERR

# ----------------------
# Variable definitions
# ----------------------
BUILD_DIR="build"              # Directory for CMake build output
RELEASE_DIR="output"           # Output directory for headers and libs
BUILD_TYPE="Release"           # Default build type (Release or Debug)
FORCE_CLEAN=0                  # Clean build flag

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
        *)
            echo "Unknown argument: $arg"
            echo "Usage: $0 [clean] [debug]"
            exit 1
            ;;
    esac
done

echo "Build type: $BUILD_TYPE"

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
# Clean previous builds
# ----------------------
echo "## Clean old build files ##"
rm -rf "$BUILD_DIR"

if [ "$FORCE_CLEAN" -eq 1 ]; then
    rm -rf "$RELEASE_DIR"
fi

# ----------------------
# Configure and build
# ----------------------
echo "## Building HDF5 static libraries ##"
cmake -S . -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE:STRING="$BUILD_TYPE"
cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" --parallel

# ----------------------
# Completion message
# ----------------------
echo "Build completed successfully. Output in $RELEASE_DIR."
