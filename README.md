# HDF5-lib-build

This directory contains scripts and GitHub Actions workflows for building HDF5 static libraries and headers for use with the radarsimpy project. The build system supports multiple platforms and architectures, including Ubuntu (x86_64), Windows (x86_64), and MacOS (x86_64, Apple Silicon).

## Contents

- **build.sh**: Main build script for Unix-like systems (Linux, MacOS). Cleans, configures, builds, and collects HDF5 static libraries and headers.
- **build.bat**: Windows batch build script.
- **GitHub Actions Workflows** (`.github/workflows/`):
  - `release_ubuntu.yml`: Builds and archives HDF5 libraries for Ubuntu x86_64.
  - `release_windows.yml`: Builds and archives HDF5 libraries for Windows x86_64.
  - `release_macos.yml`: Builds and archives HDF5 libraries for both MacOS x86_64 and Apple Silicon (arm64).
- **hdf5/**: HDF5 source code (as a submodule or downloaded source).
- **libs/**: Pre-built libraries (see below).

## Pre-built Libraries

The `libs/` folder contains pre-built HDF5 static libraries for all supported platforms:

### Directory Structure

```
libs/
├── include/                  # Common HDF5 C/C++ headers
├── include_linux_x86_64/     # Linux-specific generated headers
├── include_macos_arm64/      # macOS ARM64-specific generated headers
├── include_macos_x86_64/     # macOS x86_64-specific generated headers
├── include_win_x86_64/       # Windows-specific generated headers
│
├── lib_linux_x86_64/         # Linux x86_64 static libraries
│   ├── libhdf5.a
│   ├── libhdf5_cpp.a
│   ├── libhdf5_hl.a
│   └── libhdf5_hl_cpp.a
│
├── lib_macos_arm64/          # macOS Apple Silicon static libraries
│   ├── libhdf5.a
│   ├── libhdf5_cpp.a
│   ├── libhdf5_hl.a
│   └── libhdf5_hl_cpp.a
│
├── lib_macos_x86_64/         # macOS Intel static libraries
│   ├── libhdf5.a
│   ├── libhdf5_cpp.a
│   ├── libhdf5_hl.a
│   └── libhdf5_hl_cpp.a
│
└── lib_win_x86_64/           # Windows x86_64 static libraries
    ├── libhdf5.lib
    ├── libhdf5_cpp.lib
    ├── libhdf5_hl.lib
    └── libhdf5_hl_cpp.lib
```

### Library Descriptions

| Library | Description |
|---------|-------------|
| `libhdf5` | Core HDF5 C library |
| `libhdf5_cpp` | HDF5 C++ wrapper library |
| `libhdf5_hl` | HDF5 High-Level C API (simplified interface) |
| `libhdf5_hl_cpp` | HDF5 High-Level C++ API |

### Platform Support

| Platform | Architecture | Library Format | Runner | Compiler | Notes |
|----------|--------------|----------------|--------|----------|-------|
| Linux (Ubuntu 22.04) | x86_64 | `.a` (static) | `ubuntu-22.04` | GCC 11 (`gcc-11`/`g++-11`) | |
| macOS | x86_64 (Intel) | `.a` (static) | `macos-15-intel` | GCC 14 (`gcc-14`/`g++-14`) | Xcode 16.4 |
| macOS | arm64 (Apple Silicon) | `.a` (static) | `macos-15` | Clang (`clang`/`clang++`) | Xcode 16.4 |
| Windows | x86_64 | `.lib` (static) | `windows-2025` | MSVC | Visual Studio |

## Usage

### Using Pre-built Libraries

The pre-built libraries in `libs/` are ready to use. In your CMake project:

```cmake
# Set platform-specific library path
if(WIN32)
    set(HDF5_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/hdf5-lib-build/libs/lib_win_x86_64")
    set(HDF5_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/hdf5-lib-build/libs/include_win_x86_64")
elseif(APPLE)
    if(CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
        set(HDF5_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/hdf5-lib-build/libs/lib_macos_arm64")
        set(HDF5_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/hdf5-lib-build/libs/include_macos_arm64")
    else()
        set(HDF5_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/hdf5-lib-build/libs/lib_macos_x86_64")
        set(HDF5_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/hdf5-lib-build/libs/include_macos_x86_64")
    endif()
else()
    set(HDF5_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/hdf5-lib-build/libs/lib_linux_x86_64")
    set(HDF5_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/hdf5-lib-build/libs/include_linux_x86_64")
endif()

# Include common headers
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/hdf5-lib-build/libs/include")
include_directories("${HDF5_INCLUDE_DIR}")

# Link libraries
target_link_libraries(your_target
    ${HDF5_LIB_DIR}/libhdf5_cpp${LIB_EXT}
    ${HDF5_LIB_DIR}/libhdf5_hl_cpp${LIB_EXT}
    ${HDF5_LIB_DIR}/libhdf5_hl${LIB_EXT}
    ${HDF5_LIB_DIR}/libhdf5${LIB_EXT}
)
```

### Building from Source

The build scripts support both Release (default) and Debug configurations.

#### Linux / MacOS

```sh
chmod +x build.sh

# Release build (default)
./build.sh

# Debug build
./build.sh debug

# Clean build
./build.sh clean

# Clean Debug build
./build.sh clean debug
```

#### Windows

```bat
# Release build (default)
build.bat

# Debug build
build.bat debug

# Clean build
build.bat clean

# Clean Debug build
build.bat clean debug
```

**Output:**
- Release builds: `output/` directory
- Debug builds: `output/` directory (with debug symbols included)

**Note:** Arguments can be provided in any order (e.g., `./build.sh debug clean` works the same as `./build.sh clean debug`).

### Continuous Integration

GitHub Actions workflows are provided for automated builds on push or pull request to the `main` branch. Artifacts are uploaded for each platform and architecture.

#### Build Matrix

| Workflow | Platform | Artifact Name | Retention |
|----------|----------|---------------|-----------|
| `release_ubuntu.yml` | Ubuntu 22.04 x86_64 | `hdf5lib_ubuntu-22.04_x86_64` | 14 days |
| `release_windows.yml` | Windows x86_64 | `hdf5lib_win_x86_64` | 14 days |
| `release_macos.yml` | macOS x86_64 (Intel) | `hdf5lib_macos_x86_64` | 14 days |
| `release_macos.yml` | macOS arm64 (Apple Silicon) | `hdf5lib_macos_arm64` | 14 days |

## Customization

- Edit the build scripts to adjust CMake options or add dependencies as needed.
- Update workflow files in `.github/workflows/` to add more platforms or change build matrix settings.

---

For more details, see the comments in each script and workflow file.
