# -----------------------------------------------------------------------------
# HDF5 recipe
# -----------------------------------------------------------------------------
# Downloads a pinned HDF5 release with FetchContent, builds the static C/C++
# libraries and stages the result into ${DEPS_OUTPUT_DIR}/hdf5.
#
# Driven by the superbuild in ../../CMakeLists.txt; configure it directly only
# when debugging this one dependency:
#
#   cmake -S recipes/hdf5 -B build/hdf5 -DDEPS_OUTPUT_DIR=$PWD/output
#   cmake --build build/hdf5 --parallel
# -----------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.26)

project(hdf5_recipe LANGUAGES C CXX)

include(FetchContent)

set(DEPS_ROOT "${PROJECT_SOURCE_DIR}/../..")
list(APPEND CMAKE_MODULE_PATH "${DEPS_ROOT}/cmake")

include(baseline)
include(platform)

set(DEPS_OUTPUT_DIR "${DEPS_ROOT}/output" CACHE PATH "Directory to stage into")
set(HDF5_STAGE_DIR "${DEPS_OUTPUT_DIR}/hdf5")

# -----------------------------------------------------------------------------
# Source location and version pin
# -----------------------------------------------------------------------------
set(HDF5_GIT_REPOSITORY "https://github.com/HDFGroup/hdf5.git"
    CACHE STRING "Git repository to fetch the HDF5 source from")
set(HDF5_GIT_TAG "2.1.1"
    CACHE STRING "HDF5 release tag to build")

# -----------------------------------------------------------------------------
# Output directories
# -----------------------------------------------------------------------------
# HDF5 only sets these itself when it is the top-level project (see
# SET_HDF_OUTPUT_DIRS in config/HDFMacros.cmake). Built as a sub-project it
# leaves them alone, so set them here to collect every library in build/bin.
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin")

# -----------------------------------------------------------------------------
# HDF5 build options
# -----------------------------------------------------------------------------
# HDF5 declares some of these with option() and some with set(... CACHE ...),
# so force the cache entries to make sure both kinds are overridden.
# BUILD_SHARED_LIBS / BUILD_STATIC_LIBS / BUILD_TESTING come from baseline.cmake.
set(HDF5_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
set(HDF5_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(HDF5_BUILD_UTILS OFF CACHE BOOL "" FORCE)
set(HDF5_BUILD_CPP_LIB ON CACHE BOOL "" FORCE)
set(HDF5_BUILD_HL_LIB ON CACHE BOOL "" FORCE)
set(HDF5_BUILD_FORTRAN OFF CACHE BOOL "" FORCE)
set(HDF5_BUILD_JAVA OFF CACHE BOOL "" FORCE)
set(HDF5_ENABLE_SZIP_SUPPORT OFF CACHE BOOL "" FORCE)
set(HDF5_ENABLE_ZLIB_SUPPORT OFF CACHE BOOL "" FORCE)

# -----------------------------------------------------------------------------
# Fetch and build
# -----------------------------------------------------------------------------
message(STATUS "HDF5 source: ${HDF5_GIT_REPOSITORY} @ ${HDF5_GIT_TAG}")
message(STATUS "HDF5 staging platform: ${DEPS_PLATFORM}")

FetchContent_Declare(
    hdf5
    GIT_REPOSITORY "${HDF5_GIT_REPOSITORY}"
    GIT_TAG "${HDF5_GIT_TAG}"
    GIT_SHALLOW TRUE
    GIT_PROGRESS TRUE
)
FetchContent_MakeAvailable(hdf5)

# -----------------------------------------------------------------------------
# Stage headers and libraries
# -----------------------------------------------------------------------------
# The copying is done by a script run at build time so that the file globs pick
# up everything the build generated, and so that the header list never has to
# fit on a command line.
add_custom_target(stage ALL
    COMMAND ${CMAKE_COMMAND}
        "-DHDF5_SOURCE_DIR=${hdf5_SOURCE_DIR}"
        "-DHDF5_BUILD_DIR=${hdf5_BINARY_DIR}"
        "-DHDF5_LIB_DIR=$<TARGET_FILE_DIR:hdf5-static>"
        "-DOUTPUT_DIR=${HDF5_STAGE_DIR}"
        "-DPLATFORM=${DEPS_PLATFORM}"
        -P "${DEPS_ROOT}/cmake/stage_hdf5.cmake"
    COMMENT "Staging HDF5 headers and libraries into ${HDF5_STAGE_DIR}"
    VERBATIM
)

add_dependencies(stage
    hdf5-static
    hdf5_cpp-static
    hdf5_hl-static
    hdf5_hl_cpp-static
)
