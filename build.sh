#!/bin/bash
# ============================================================================
# build.sh - Build script for HDF5 static libraries
#
# This script automates the process of building the C++ library and preparing
# the HDF5 static libraries and headers for use with radarsimpy.
#
# Usage:
#   ./build.sh
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
HDF5LIB_DIR="hdf5lib"          # Output directory for headers and libs
HDF5_SRC="../hdf5"             # Path to HDF5 source directory

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
rm -rf "$BUILD_DIR" "$HDF5LIB_DIR"

# ----------------------
# Configure and build
# ----------------------
echo "## Building HDF5 static libraries ##"
mkdir "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure the project with CMake
cmake -DCMAKE_BUILD_TYPE:STRING=Release \
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
install -d "$HDF5LIB_DIR/include" "$HDF5LIB_DIR/lib"

# Copy header files from HDF5 and build output
echo "## Copying header and library files to $HDF5LIB_DIR ##"
install -m 644 ./hdf5/c++/src/*.h "$HDF5LIB_DIR/include/"
install -m 644 ./hdf5/src/*.h "$HDF5LIB_DIR/include/"
install -m 644 ./hdf5/src/H5FDsubfiling/*.h "$HDF5LIB_DIR/include/"
install -m 644 ./build/src/*.h "$HDF5LIB_DIR/include/"

# Copy static library files
install -m 644 ./build/bin/*.a "$HDF5LIB_DIR/lib/"

# ----------------------
# Completion message
# ----------------------
echo "Build completed successfully. Output in $HDF5LIB_DIR."
