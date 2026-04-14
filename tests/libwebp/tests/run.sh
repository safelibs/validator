#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

# Run only against the imported tagged-port mirror, never a sibling checkout.
readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly library_root=${VALIDATOR_LIBRARY_ROOT:?}
readonly work_root=$(mktemp -d)
readonly shadow_root="$work_root/root"
readonly safe_root="$shadow_root/safe"
readonly original_root="$shadow_root/original"
readonly multiarch="$(validator_multiarch)"
readonly current_lib_root="/usr/lib/$multiarch"
readonly oracle_lib_root="$library_root/original-package-root/usr/lib/$multiarch"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_dir "$tagged_root/safe/tests"
validator_require_dir "$tagged_root/safe/tests/c"
validator_require_dir "$tagged_root/original/examples"
validator_require_file "$tagged_root/original/tests/public_api_test.c"
validator_require_dir "$oracle_lib_root"

validator_copy_tree "$tagged_root/safe/tests" "$safe_root/tests"
validator_copy_tree "$tagged_root/original/examples" "$original_root/examples"
mkdir -p "$original_root/tests"
validator_copy_file "$tagged_root/original/tests/public_api_test.c" "$original_root/tests/public_api_test.c"

glue_dir="$work_root/include-glue/src/webp"
mkdir -p "$glue_dir"
for header in decode.h demux.h encode.h mux.h mux_types.h types.h; do
  ln -sf "/usr/include/webp/$header" "$glue_dir/$header"
done

cmake \
  -S "$safe_root/tests/c" \
  -B "$work_root/c-build" \
  -DTEST_SUITE=all \
  -DWEBP_INCLUDE_DIR=/usr/include \
  -DWEBPDECODER_LIBRARY="$current_lib_root/libwebpdecoder.so" \
  -DWEBPDEMUX_LIBRARY="$current_lib_root/libwebpdemux.so" \
  -DWEBP_LIBRARY="$current_lib_root/libwebp.so" \
  -DORACLE_WEBPDECODER_LIBRARY="$oracle_lib_root/libwebpdecoder.so" \
  -DORACLE_WEBPDEMUX_LIBRARY="$oracle_lib_root/libwebpdemux.so" \
  -DORACLE_WEBP_LIBRARY="$oracle_lib_root/libwebp.so" \
  -DTEST_WEBP_PATH="$original_root/examples/test.webp" \
  -DTEST_PPM_PATH="$original_root/examples/test_ref.ppm"
cmake --build "$work_root/c-build" -j"$(nproc)"
ctest --test-dir "$work_root/c-build" --output-on-failure

cmake \
  -S "$safe_root/tests/c" \
  -B "$work_root/public-api-build" \
  -DTEST_SUITE=upstream_public_api \
  -DWEBP_INCLUDE_DIR=/usr/include \
  -DWEBPMUX_LIBRARY="$current_lib_root/libwebpmux.so" \
  -DWEBPDEMUX_LIBRARY="$current_lib_root/libwebpdemux.so" \
  -DWEBP_LIBRARY="$current_lib_root/libwebp.so" \
  -DUPSTREAM_PUBLIC_API_SOURCE="$original_root/tests/public_api_test.c" \
  -DUPSTREAM_INCLUDE_GLUE_DIR="$work_root/include-glue"
cmake --build "$work_root/public-api-build" -j"$(nproc)"
ctest --test-dir "$work_root/public-api-build" --output-on-failure

pkg-config --exists libwebp
pkg-config --exists libsharpyuv
pkg-config --exists libwebpdecoder
pkg-config --exists libwebpdemux
pkg-config --exists libwebpmux

cat >"$work_root/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.16)
project(webp_smoke C)
find_package(PkgConfig REQUIRED)
pkg_check_modules(WEBP REQUIRED libwebp)
add_executable(webp_smoke main.c)
target_include_directories(webp_smoke PRIVATE ${WEBP_INCLUDE_DIRS})
target_link_libraries(webp_smoke PRIVATE ${WEBP_LIBRARIES})
EOF
cat >"$work_root/main.c" <<'EOF'
#include <webp/decode.h>
int main(void) { return WebPGetDecoderVersion() == 0; }
EOF
cmake -S "$work_root" -B "$work_root/cmake-build"
cmake --build "$work_root/cmake-build" -j"$(nproc)"
"$work_root/cmake-build/webp_smoke"

cwebp -quiet "$original_root/examples/test_ref.ppm" -o "$work_root/cwebp.webp"
test -s "$work_root/cwebp.webp"
dwebp "$original_root/examples/test.webp" -ppm -o "$work_root/dwebp.ppm" >/dev/null
test -s "$work_root/dwebp.ppm"
webpinfo "$original_root/examples/test.webp" >/dev/null
