# HDF5-lib-build

This directory contains scripts and GitHub Actions workflows for building HDF5 static libraries and headers for use with the radarsimpy project. The build system supports multiple platforms and architectures, including Ubuntu (22.04, 24.04), Windows (x86_64), and MacOS (x86_64, Apple Silicon).

## Contents

- **build.sh**: Main build script for Unix-like systems (Linux, MacOS). Cleans, configures, builds, and collects HDF5 static libraries and headers.
- **build.bat**: Windows batch build script.
- **GitHub Actions Workflows** (`.github/workflows/`):
  - `release_ubuntu_multi_x86_64.yml`: Builds and archives HDF5 libraries for Ubuntu 22.04 and 24.04.
  - `release_windows_x86_64.yml`: Builds and archives HDF5 libraries for Windows x86_64.
  - `release_macos.yml`: Builds and archives HDF5 libraries for both MacOS x86_64 and Apple Silicon (arm64).
- **hdf5/**: HDF5 source code (as a submodule or downloaded source).
- **hdf5lib/**: Output directory for built static libraries and headers.

## Usage

### Local Build

#### Linux / MacOS

```sh
chmod +x build.sh
./build.sh
```

#### Windows

```bat
build.bat
```

The output will be placed in the `hdf5lib/` directory.

### Continuous Integration

GitHub Actions workflows are provided for automated builds on push or pull request to the `main` branch. Artifacts are uploaded for each platform and architecture.

## Customization

- Edit the build scripts to adjust CMake options or add dependencies as needed.
- Update workflow files in `.github/workflows/` to add more platforms or change build matrix settings.

---

For more details, see the comments in each script and workflow file.
