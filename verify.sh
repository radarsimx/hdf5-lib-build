#!/bin/bash
# ============================================================================
# verify.sh - Sanity check the staged output of a dependency build
#
# Usage:
#   ./verify.sh <platform>
#
# Example:
#   ./verify.sh linux_x86_64
#
# Checks that every dependency present in ./output actually staged the static
# libraries RadarSimCpp links, under the expected platform directory. A build
# that compiles fine but stages nothing is the failure mode worth catching
# here - the alternative is an unresolved-symbol error in a RadarSimCpp build
# days later, with nothing pointing back at this repo.
#
# Runs on Windows too (via Git Bash), which is why it is one script rather than
# duplicated shell snippets in each workflow.
# ============================================================================

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <platform>" >&2
    exit 1
fi

PLATFORM="$1"
OUTPUT_DIR="output"
FAILED=0

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "ERROR: '$OUTPUT_DIR' does not exist - nothing was built" >&2
    exit 1
fi

# Library basenames, without the platform-specific prefix/suffix.
HDF5_LIBS="hdf5 hdf5_cpp hdf5_hl hdf5_hl_cpp"
MBEDTLS_LIBS="mbedtls mbedx509 tfpsacrypto"

# MSVC produces <name>.lib; the HDF5 build already prefixes its own targets
# with "lib", which is why libhdf5.lib is correct and mbedtls.lib is too.
case "$PLATFORM" in
    win_*)
        HDF5_PREFIX="lib"; HDF5_SUFFIX=".lib"
        MBEDTLS_PREFIX="";  MBEDTLS_SUFFIX=".lib"
        ;;
    *)
        HDF5_PREFIX="lib"; HDF5_SUFFIX=".a"
        MBEDTLS_PREFIX="lib"; MBEDTLS_SUFFIX=".a"
        ;;
esac

check_dep() {
    local dep="$1" prefix="$2" suffix="$3" libs="$4"
    local dep_dir="$OUTPUT_DIR/$dep"

    if [ ! -d "$dep_dir" ]; then
        echo "SKIP: $dep was not built"
        return 0
    fi

    echo "=== $dep ==="

    local lib_dir="$dep_dir/lib_$PLATFORM"
    if [ ! -d "$lib_dir" ]; then
        echo "ERROR: $lib_dir not found" >&2
        FAILED=1
        return 0
    fi

    if [ ! -d "$dep_dir/include" ]; then
        echo "ERROR: $dep_dir/include not found" >&2
        FAILED=1
    fi

    local lib
    for lib in $libs; do
        local path="$lib_dir/${prefix}${lib}${suffix}"
        if [ ! -f "$path" ]; then
            echo "ERROR: required library $path not found" >&2
            FAILED=1
        fi
    done

    ls -lh "$lib_dir"
}

check_dep hdf5 "$HDF5_PREFIX" "$HDF5_SUFFIX" "$HDF5_LIBS"
check_dep mbedtls "$MBEDTLS_PREFIX" "$MBEDTLS_SUFFIX" "$MBEDTLS_LIBS"

if [ -f "$OUTPUT_DIR/manifest.txt" ]; then
    echo "=== manifest ==="
    cat "$OUTPUT_DIR/manifest.txt"
else
    echo "ERROR: $OUTPUT_DIR/manifest.txt not found" >&2
    FAILED=1
fi

if [ "$FAILED" -ne 0 ]; then
    echo "" >&2
    echo "[FAILED] Staged output is incomplete" >&2
    exit 1
fi

echo ""
echo "[SUCCESS] Staged output verified for $PLATFORM"
