#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

# Run only against the imported tagged-port mirror, never a sibling checkout.
readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly work_root=$(mktemp -d)
readonly safe_root="$work_root/safe"
readonly original_root="$work_root/original"
readonly multiarch="$(validator_multiarch)"
readonly system_lib_root="/usr/lib/$multiarch"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_dir "$tagged_root/safe/tests"
validator_require_dir "$tagged_root/original/tests"
validator_require_dir "$tagged_root/original/pic"
validator_require_file "$tagged_root/original/gif_lib.h"
validator_require_file "$system_lib_root/libgif.a"
validator_require_file "$system_lib_root/libgif.so"

validator_copy_tree "$tagged_root/safe/tests" "$safe_root/tests"
validator_copy_tree "$tagged_root/original/tests" "$original_root/tests"
validator_copy_tree "$tagged_root/original/pic" "$original_root/pic"
validator_copy_file "$tagged_root/original/gif_lib.h" "$safe_root/include/gif_lib.h"
validator_copy_file "$tagged_root/original/gif_lib.h" "$original_root/gif_lib.h"

mkdir -p \
  "$safe_root/target/release" \
  "$safe_root/debian/pkgconfig"
ln -sf "$system_lib_root/libgif.a" "$safe_root/target/release/libgif.a"
ln -sf "$system_lib_root/libgif.so" "$safe_root/target/release/libgif.so"

cat >"$safe_root/debian/pkgconfig/libgif7.pc.in" <<'EOF'
prefix=/usr
exec_prefix=${prefix}
libdir=${exec_prefix}/lib/@DEB_TARGET_MULTIARCH@
includedir=${prefix}/include

Name: giflib
Description: GIF image library
Version: @VERSION@
Libs: -L${libdir} -lgif
Cflags: -I${includedir}
EOF

cat >"$safe_root/debian/changelog" <<'EOF'
giflib (5.2.2-0validator1) noble; urgency=medium

  * Validator runtime-only harness.

 -- Validator <validator@example.invalid>  Mon, 01 Jan 2024 00:00:00 +0000
EOF

export LD_LIBRARY_PATH="$safe_root/target/release${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

make -C "$safe_root/tests" clean >/dev/null 2>&1 || true
make -C "$safe_root/tests" \
  test \
  gif2rgb-regress \
  safe-header-regress \
  link-compat-regress
