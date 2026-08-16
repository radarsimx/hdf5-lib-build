# -----------------------------------------------------------------------------
# stage_mbedtls.cmake - collect mbedTLS headers and static libraries
# -----------------------------------------------------------------------------
# Run with `cmake -P` from the `stage` target defined in
# recipes/mbedtls/CMakeLists.txt. Expects the following variables via -D:
#
#   INCLUDE_DIRS - '|' separated list of header search roots, taken from the
#                  mbedTLS targets' INTERFACE_INCLUDE_DIRECTORIES
#   LIB_FILES    - '|' separated list of built static library paths
#   OUTPUT_DIR   - Directory to stage into
#   PLATFORM     - Platform suffix, e.g. linux_x86_64 or win_x86_64
#
# Produces:
#   ${OUTPUT_DIR}/include/         - Headers, relative layout preserved
#   ${OUTPUT_DIR}/lib_${PLATFORM}/ - Static libraries
#
# Unlike HDF5, mbedTLS has no platform-probed public header: its configuration
# comes from the build options this repo forces, which are the same everywhere.
# So the headers go in a single shared include/ directory with no per-platform
# variant, and every platform's build writes an identical copy.
# -----------------------------------------------------------------------------

foreach(_required IN ITEMS INCLUDE_DIRS LIB_FILES OUTPUT_DIR PLATFORM)
    if(NOT DEFINED ${_required})
        message(FATAL_ERROR "stage_mbedtls.cmake: ${_required} is not set")
    endif()
endforeach()

string(REPLACE "|" ";" INCLUDE_DIRS "${INCLUDE_DIRS}")
string(REPLACE "|" ";" LIB_FILES "${LIB_FILES}")

set(INCLUDE_DIR "${OUTPUT_DIR}/include")
set(LIB_DIR "${OUTPUT_DIR}/lib_${PLATFORM}")

file(MAKE_DIRECTORY "${INCLUDE_DIR}" "${LIB_DIR}")

# -----------------------------------------------------------------------------
# Headers
# -----------------------------------------------------------------------------
# Each include root is copied with its internal structure intact, so
# <mbedtls/pk.h> and <psa/crypto.h> keep resolving the way the sources expect.
set(HEADER_COUNT 0)
foreach(_dir IN LISTS INCLUDE_DIRS)
    if(_dir STREQUAL "" OR NOT IS_DIRECTORY "${_dir}")
        continue()
    endif()

    file(GLOB_RECURSE _headers RELATIVE "${_dir}" "${_dir}/*.h" "${_dir}/*.hpp")
    foreach(_header IN LISTS _headers)
        get_filename_component(_subdir "${_header}" DIRECTORY)
        file(COPY "${_dir}/${_header}" DESTINATION "${INCLUDE_DIR}/${_subdir}")
        math(EXPR HEADER_COUNT "${HEADER_COUNT} + 1")
    endforeach()
endforeach()

if(HEADER_COUNT EQUAL 0)
    message(FATAL_ERROR
        "stage_mbedtls.cmake: no headers found in any of: ${INCLUDE_DIRS}")
endif()

# The headers RadarSimCpp's license verifier actually includes. Checking them
# here means a layout change in a future mbedTLS release fails in this repo,
# where the fix belongs, instead of as a confusing #include error in a
# downstream RadarSimCpp build weeks later.
foreach(_expected IN ITEMS
        mbedtls/base64.h
        mbedtls/error.h
        mbedtls/md.h
        mbedtls/pk.h
        mbedtls/version.h
        psa/crypto.h)
    if(NOT EXISTS "${INCLUDE_DIR}/${_expected}")
        message(FATAL_ERROR
            "stage_mbedtls.cmake: required header '${_expected}' was not staged. "
            "mbedTLS moved its headers; check the include roots reported by the "
            "mbedtls/mbedx509/tfpsacrypto targets.")
    endif()
endforeach()

# -----------------------------------------------------------------------------
# Static libraries
# -----------------------------------------------------------------------------
foreach(_lib IN LISTS LIB_FILES)
    if(NOT EXISTS "${_lib}")
        message(FATAL_ERROR "stage_mbedtls.cmake: library '${_lib}' does not exist")
    endif()
    file(COPY "${_lib}" DESTINATION "${LIB_DIR}")
endforeach()

list(LENGTH LIB_FILES LIBRARY_COUNT)
if(LIBRARY_COUNT EQUAL 0)
    message(FATAL_ERROR "stage_mbedtls.cmake: no static libraries to stage")
endif()

message(STATUS "Staged ${HEADER_COUNT} headers to ${INCLUDE_DIR}")
message(STATUS "Staged ${LIBRARY_COUNT} libraries to ${LIB_DIR}")
