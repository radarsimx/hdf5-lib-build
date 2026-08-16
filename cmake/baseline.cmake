# -----------------------------------------------------------------------------
# baseline.cmake - the ABI baseline every prebuilt dependency is built against
# -----------------------------------------------------------------------------
# Prebuilt static libraries are only usable if they were compiled against the
# same ABI as the consumer that links them. This file is included by every
# recipe so that all dependencies agree, and it documents what the consumer
# (radarsimcpp) expects.
#
# The rules:
#
#   Position independent code
#       Everything ends up inside radarsimcpp, which is a SHARED library, so
#       every object linked into it must be PIC. Without this, Linux builds
#       fail at link time with "recompile with -fPIC".
#
#   MSVC runtime
#       radarsimcpp links the dynamic release CRT (/MD). Debug builds of
#       radarsimcpp therefore mix /MDd objects with these /MD libraries, which
#       is why the consumer passes /NODEFAULTLIB:MSVCRTD. Building the deps
#       with /MDd instead would only move the problem to release builds, which
#       are the ones that ship, so /MD is the deliberate choice here.
#
#   macOS deployment target
#       Left at the toolchain default unless DEPS_OSX_DEPLOYMENT_TARGET is set.
#       Set it (here or on the command line) if the wheels ever need to support
#       an older macOS than the CI runner's SDK defaults to - a prebuilt library
#       cannot be consumed by a build with an *older* deployment target than the
#       one it was compiled with.
#
#   Static only
#       No shared objects are produced. The point of the prebuilt libraries is
#       that a radarsimcpp wheel has no runtime dependency to ship alongside it.
# -----------------------------------------------------------------------------

set(CMAKE_POSITION_INDEPENDENT_CODE ON CACHE BOOL "" FORCE)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(BUILD_STATIC_LIBS ON CACHE BOOL "" FORCE)

# Nothing in a dependency's own test suite is useful to us and it roughly
# doubles the build time.
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)

if(MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL" CACHE STRING "" FORCE)
endif()

set(DEPS_OSX_DEPLOYMENT_TARGET "" CACHE STRING
    "macOS deployment target to build the prebuilt libraries against (empty = toolchain default)")

if(APPLE AND DEPS_OSX_DEPLOYMENT_TARGET)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "${DEPS_OSX_DEPLOYMENT_TARGET}" CACHE STRING "" FORCE)
endif()
