#!/bin/bash
# ============================================================================
# build.sh - Build script for HDF5 static libraries
#
# This script automates the process of building the C++ library and preparing
# the HDF5 static libraries and headers for use with radarsimpy.
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
#   - cmake
#   - install (GNU coreutils)
#
# The script will:
#   1. Clean previous build and output directories
#   2. Configure and build the project using CMake
#   3. Collect and organize the resulting headers and static libraries
#   4. Output results to the hdf5lib directory
# ============================================================================

set -euo pipefail
trap 'echo "Error: Command failed at line $LINENO: $BASH_COMMAND" >&2' ERR

# ----------------------
# Variable definitions
# ----------------------
WORKPATH=$(pwd)                # Current working directory
BUILD_DIR="build"              # Directory for CMake build output
RELEASE_DIR="output"          # Output directory for headers and libs
HDF5_SRC="../hdf5"             # Path to HDF5 source directory
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

# Detect OS and architecture
OS_TYPE=$(uname -s)
ARCH_TYPE=$(uname -m)

case "$OS_TYPE" in
    Linux*)
        PLATFORM="linux_${ARCH_TYPE}"
        ;;
    Darwin*)
        if [ "$ARCH_TYPE" = "arm64" ]; then
            PLATFORM="macos_arm64"
        else
            PLATFORM="macos_x86_64"
        fi
        ;;
esac

echo "Detected platform: $PLATFORM"
echo "Build type: $BUILD_TYPE"

# ----------------------
# Check for dependencies
# ----------------------
for cmd in cmake install; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed." >&2
        exit 1
    fi
done

# ----------------------
# Clean previous builds
# ----------------------
echo "## Clean old build files ##"
rm -rf "$BUILD_DIR" "$RELEASE_DIR"

# ----------------------
# Configure and build
# ----------------------
echo "## Building HDF5 static libraries ##"
mkdir "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure the project with CMake
cmake -DCMAKE_BUILD_TYPE:STRING=$BUILD_TYPE \
      -DBUILD_SHARED_LIBS:BOOL=OFF \
      -DBUILD_TESTING:BOOL=OFF \
      -DHDF5_BUILD_TOOLS:BOOL=OFF \
      -DHDF5_BUILD_EXAMPLES:BOOL=OFF \
      -DHDF5_BUILD_UTILS:BOOL=OFF \
      -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF \
      -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=OFF \
      -DHDF5_BUILD_CPP_LIB:BOOL=ON "$HDF5_SRC"

# Build the project
cmake --build .

# Return to the original working directory
cd "$WORKPATH"

# ----------------------
# Organize output files
# ----------------------
# Create output directories for headers and libraries
install -d "$RELEASE_DIR/include" "$RELEASE_DIR/include_${PLATFORM}" "$RELEASE_DIR/lib_${PLATFORM}"

# Copy header files from HDF5 and build output
echo "## Copying header and library files to $RELEASE_DIR ##"
install -m 644 ./hdf5/c++/src/*.h "$RELEASE_DIR/include/"
install -m 644 ./hdf5/src/*.h "$RELEASE_DIR/include/"
install -m 644 ./hdf5/src/H5FDsubfiling/*.h "$RELEASE_DIR/include/"
install -m 644 ./build/src/*.h "$RELEASE_DIR/include_${PLATFORM}/"

# Copy static library files
install -m 644 ./build/bin/*.a "$RELEASE_DIR/lib_${PLATFORM}/"

# ----------------------
# Completion message
# ----------------------
echo "Build completed successfully. Output in $RELEASE_DIR."
