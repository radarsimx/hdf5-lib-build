# -----------------------------------------------------------------------------
# package_release.cmake - archive a staged dependency for a GitHub release
# -----------------------------------------------------------------------------
# Run with `cmake -P` after a build has staged into output/. Expects:
#
#   DEP        - Dependency name, e.g. hdf5 or mbedtls
#   VERSION    - Version of that dependency, e.g. 2.1.1
#   PLATFORM   - Platform suffix, e.g. linux_x86_64
#   STAGE_DIR  - Directory holding the staged tree (output/<dep>)
#   DIST_DIR   - Directory to write the archive and checksum into
#
# Produces:
#   ${DIST_DIR}/<dep>-<version>-<platform>.tar.gz
#   ${DIST_DIR}/<dep>-<version>-<platform>.tar.gz.sha256
#
# The archive is rooted at the staged tree itself, so extracting it yields
# include/, include_<platform>/ and lib_<platform>/ directly. That is the exact
# layout radarsimcpp's setup_prebuilt_dep() expects to find, whether it came
# from this archive or from a submodule checkout.
#
# The .sha256 file is what makes the download path trustworthy: the consumer
# pins the hash in cmake/deps_manifest.cmake and refuses anything that does not
# match, so a re-tagged or tampered release cannot silently change what gets
# linked into a wheel.
# -----------------------------------------------------------------------------

foreach(_required IN ITEMS DEP VERSION PLATFORM STAGE_DIR DIST_DIR)
    if(NOT DEFINED ${_required})
        message(FATAL_ERROR "package_release.cmake: ${_required} is not set")
    endif()
endforeach()

if(NOT IS_DIRECTORY "${STAGE_DIR}")
    message(FATAL_ERROR "package_release.cmake: staged directory '${STAGE_DIR}' does not exist")
endif()

set(ARCHIVE_NAME "${DEP}-${VERSION}-${PLATFORM}.tar.gz")
set(ARCHIVE_PATH "${DIST_DIR}/${ARCHIVE_NAME}")

file(MAKE_DIRECTORY "${DIST_DIR}")

# Only the directories that belong to this platform, so a per-platform archive
# never carries another platform's binaries.
set(_contents "include")
foreach(_dir "include_${PLATFORM}" "lib_${PLATFORM}")
    if(IS_DIRECTORY "${STAGE_DIR}/${_dir}")
        list(APPEND _contents "${_dir}")
    endif()
endforeach()

if(NOT IS_DIRECTORY "${STAGE_DIR}/lib_${PLATFORM}")
    message(FATAL_ERROR
        "package_release.cmake: '${STAGE_DIR}/lib_${PLATFORM}' is missing - "
        "nothing was built for this platform")
endif()

execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar czf "${ARCHIVE_PATH}" -- ${_contents}
    WORKING_DIRECTORY "${STAGE_DIR}"
    RESULT_VARIABLE _tar_result
)
if(NOT _tar_result EQUAL 0)
    message(FATAL_ERROR "package_release.cmake: failed to create ${ARCHIVE_PATH}")
endif()

file(SHA256 "${ARCHIVE_PATH}" _sha256)

# Written in the format sha256sum(1) reads, so the archive can be verified with
# `sha256sum -c` as well as by the consumer's CMake code.
file(WRITE "${ARCHIVE_PATH}.sha256" "${_sha256}  ${ARCHIVE_NAME}\n")

message(STATUS "Packaged ${ARCHIVE_NAME}")
message(STATUS "  sha256: ${_sha256}")
