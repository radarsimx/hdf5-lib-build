# -----------------------------------------------------------------------------
# mbedTLS recipe
# -----------------------------------------------------------------------------
# Downloads a pinned mbedTLS release, builds the static libraries and stages
# the result into ${DEPS_OUTPUT_DIR}/mbedtls.
#
# RadarSimCpp only uses mbedTLS for license verification (see
# includes/libs/license_verifier.hpp): public key parsing, SHA-256 and
# signature verification. That is a small slice of the library, but mbedTLS 4.x
# splits it across three static libraries - mbedtls, mbedx509 and tfpsacrypto -
# so all three are staged.
#
# Driven by the superbuild in ../../CMakeLists.txt; configure it directly only
# when debugging this one dependency:
#
#   cmake -S recipes/mbedtls -B build/mbedtls -DDEPS_OUTPUT_DIR=$PWD/output
#   cmake --build build/mbedtls --parallel
# -----------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.26)

project(mbedtls_recipe LANGUAGES C CXX)

include(FetchContent)

set(DEPS_ROOT "${PROJECT_SOURCE_DIR}/../..")
list(APPEND CMAKE_MODULE_PATH "${DEPS_ROOT}/cmake")

include(baseline)
include(platform)

set(DEPS_OUTPUT_DIR "${DEPS_ROOT}/output" CACHE PATH "Directory to stage into")
set(MBEDTLS_STAGE_DIR "${DEPS_OUTPUT_DIR}/mbedtls")

# -----------------------------------------------------------------------------
# Source location and version pin
# -----------------------------------------------------------------------------
set(MBEDTLS_VERSION "4.2.0" CACHE STRING "mbedTLS release version to build")
set(MBEDTLS_URL
    "https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-${MBEDTLS_VERSION}/mbedtls-${MBEDTLS_VERSION}.tar.bz2"
    CACHE STRING "URL of the mbedTLS release tarball")

# -----------------------------------------------------------------------------
# mbedTLS build options
# -----------------------------------------------------------------------------
# BUILD_SHARED_LIBS / position independent code come from baseline.cmake.
set(ENABLE_TESTING OFF CACHE BOOL "" FORCE)
set(ENABLE_PROGRAMS OFF CACHE BOOL "" FORCE)
set(GEN_FILES OFF CACHE BOOL "" FORCE)
set(USE_STATIC_MBEDTLS_LIBRARY ON CACHE BOOL "" FORCE)
set(USE_SHARED_MBEDTLS_LIBRARY OFF CACHE BOOL "" FORCE)

# -----------------------------------------------------------------------------
# Fetch and build
# -----------------------------------------------------------------------------
message(STATUS "mbedTLS source: ${MBEDTLS_URL}")
message(STATUS "mbedTLS staging platform: ${DEPS_PLATFORM}")

FetchContent_Declare(
    mbedtls
    URL "${MBEDTLS_URL}"
)
FetchContent_MakeAvailable(mbedtls)

# -----------------------------------------------------------------------------
# Collect what to stage
# -----------------------------------------------------------------------------
# The three libraries RadarSimCpp links, in dependency order (dependents first,
# which is what a static link line needs).
set(MBEDTLS_TARGETS mbedtls mbedx509 tfpsacrypto)

foreach(_target IN LISTS MBEDTLS_TARGETS)
    if(NOT TARGET ${_target})
        message(FATAL_ERROR
            "mbedTLS ${MBEDTLS_VERSION} did not define the target '${_target}'. "
            "The library layout changed; update MBEDTLS_TARGETS here and the "
            "LIBS list in radarsimcpp's CMakeLists.txt to match.")
    endif()

    get_target_property(_type ${_target} TYPE)
    if(NOT _type STREQUAL "STATIC_LIBRARY")
        message(FATAL_ERROR
            "mbedTLS target '${_target}' is ${_type}, expected STATIC_LIBRARY. "
            "Check that USE_STATIC_MBEDTLS_LIBRARY survived into this build.")
    endif()
endforeach()

# Some mbedTLS configurations build these as separate archives rather than
# folding them into tfpsacrypto. Stage them only in that case: they also exist
# as OBJECT libraries, which have no archive file to copy and would make
# $<TARGET_FILE:...> a configure error.
foreach(_optional IN ITEMS everest p256m)
    if(TARGET ${_optional})
        get_target_property(_type ${_optional} TYPE)
        if(_type STREQUAL "STATIC_LIBRARY")
            list(APPEND MBEDTLS_TARGETS ${_optional})
            message(STATUS "mbedTLS: also staging optional library '${_optional}'")
        else()
            message(STATUS "mbedTLS: '${_optional}' is ${_type}, folded into another archive")
        endif()
    endif()
endforeach()

# Rather than guessing where mbedTLS keeps its headers - which moved between
# 3.x and 4.x, and again when PSA crypto was split out into tf-psa-crypto - ask
# the targets. The generator expressions below are evaluated at build time, so
# $<BUILD_INTERFACE:...> resolves to the real path and $<INSTALL_INTERFACE:...>
# drops out. They are joined with '|' because a bare ';' would be split into
# separate command arguments.
set(_include_genex "")
set(_lib_genex "")
foreach(_target IN LISTS MBEDTLS_TARGETS)
    list(APPEND _include_genex "$<TARGET_PROPERTY:${_target},INTERFACE_INCLUDE_DIRECTORIES>")
    list(APPEND _lib_genex "$<TARGET_FILE:${_target}>")
endforeach()

# -----------------------------------------------------------------------------
# Stage headers and libraries
# -----------------------------------------------------------------------------
add_custom_target(stage ALL
    COMMAND ${CMAKE_COMMAND}
        "-DINCLUDE_DIRS=$<JOIN:$<REMOVE_DUPLICATES:${_include_genex}>,|>"
        "-DLIB_FILES=$<JOIN:${_lib_genex},|>"
        "-DOUTPUT_DIR=${MBEDTLS_STAGE_DIR}"
        "-DPLATFORM=${DEPS_PLATFORM}"
        -P "${DEPS_ROOT}/cmake/stage_mbedtls.cmake"
    COMMENT "Staging mbedTLS headers and libraries into ${MBEDTLS_STAGE_DIR}"
    VERBATIM
)

add_dependencies(stage ${MBEDTLS_TARGETS})
