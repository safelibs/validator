#!/usr/bin/env bash
set -euo pipefail

source /validator/tests/_shared/runtime_helpers.sh

readonly tagged_root=${VALIDATOR_TAGGED_ROOT:?}
readonly work_root=$(mktemp -d)
readonly shadow_root="$work_root/root"
readonly safe_root="$shadow_root/safe"
readonly original_root="$shadow_root/original"
readonly build_root="$work_root/build"
readonly bin_root="$work_root/bin"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

validator_require_dir "$tagged_root/safe/test"
validator_require_dir "$tagged_root/safe/scripts"
validator_require_dir "$tagged_root/original/test"

validator_copy_tree "$tagged_root/safe/test" "$safe_root/test"
validator_copy_tree "$tagged_root/safe/scripts" "$safe_root/scripts"
validator_copy_tree "$tagged_root/original/test" "$original_root/test"

rm -rf "$safe_root/test/images" "$safe_root/test/refs"
ln -s "$original_root/test/images" "$safe_root/test/images"
ln -s "$original_root/test/refs" "$safe_root/test/refs"

mkdir -p "$build_root/tools" "$build_root/test" "$bin_root"
validator_make_tool_shims \
  "$build_root/tools" \
  fax2tiff ppm2tiff tiff2pdf tiff2ps tiffcmp tiffcp tiffdump tiffinfo

cat >"$safe_root/test/tif_config.h" <<'EOF'
#ifndef VALIDATOR_TIF_CONFIG_H
#define VALIDATOR_TIF_CONFIG_H
#define HAVE_UNISTD_H 1
#endif
EOF

read -r -a pkg_cflags <<<"$(pkg-config --cflags libtiff-4)"
read -r -a pkg_libs <<<"$(pkg-config --libs libtiff-4)"

compile_libtiff() {
  local output=$1
  shift
  cc \
    -std=c99 \
    -Wall \
    -Wextra \
    "-DSOURCE_DIR=\"$safe_root/test\"" \
    -I"$safe_root/test" \
    "${pkg_cflags[@]}" \
    "$@" \
    "${pkg_libs[@]}" \
    -lm \
    -o "$output"
}

compile_libtiff "$bin_root/ascii_tag" "$safe_root/test/ascii_tag.c"
compile_libtiff "$bin_root/long_tag" "$safe_root/test/long_tag.c" "$safe_root/test/check_tag.c"
compile_libtiff "$bin_root/short_tag" "$safe_root/test/short_tag.c" "$safe_root/test/check_tag.c"
compile_libtiff "$bin_root/strip_rw" "$safe_root/test/strip_rw.c" "$safe_root/test/strip.c" "$safe_root/test/test_arrays.c"
compile_libtiff "$bin_root/rewrite" "$safe_root/test/rewrite_tag.c"
compile_libtiff "$bin_root/custom_dir" "$safe_root/test/custom_dir.c"
compile_libtiff "$bin_root/custom_dir_EXIF_231" "$safe_root/test/custom_dir_EXIF_231.c"
compile_libtiff "$bin_root/defer_strile_loading" "$safe_root/test/defer_strile_loading.c"
compile_libtiff "$bin_root/defer_strile_writing" "$safe_root/test/defer_strile_writing.c"
compile_libtiff "$bin_root/test_directory" "$safe_root/test/test_directory.c"
compile_libtiff "$bin_root/test_open_options" "$safe_root/test/test_open_options.c"
compile_libtiff "$bin_root/test_append_to_strip" "$safe_root/test/test_append_to_strip.c"
compile_libtiff "$bin_root/test_rgba_readers" "$safe_root/test/test_rgba_readers.c"
compile_libtiff "$bin_root/test_tile_read_write" "$safe_root/test/test_tile_read_write.c"
compile_libtiff "$bin_root/test_ifd_loop_detection" "$safe_root/test/test_ifd_loop_detection.c"
compile_libtiff "$bin_root/testtypes" "$safe_root/test/testtypes.c"
compile_libtiff "$bin_root/test_signed_tags" "$safe_root/test/test_signed_tags.c"
compile_libtiff "$bin_root/api_custom_dir_read_smoke" "$safe_root/test/api_custom_dir_read_smoke.c"

(
  cd "$safe_root/test"
  "$bin_root/ascii_tag"
  "$bin_root/long_tag"
  "$bin_root/short_tag"
  "$bin_root/strip_rw"
  "$bin_root/rewrite"
  "$bin_root/custom_dir"
  "$bin_root/custom_dir_EXIF_231"
  "$bin_root/defer_strile_loading"
  "$bin_root/defer_strile_writing"
  "$bin_root/test_directory"
  "$bin_root/test_open_options"
  "$bin_root/test_append_to_strip"
  "$bin_root/test_rgba_readers"
  "$bin_root/test_tile_read_write"
  "$bin_root/test_ifd_loop_detection"
  "$bin_root/testtypes"
  "$bin_root/test_signed_tags"
  "$bin_root/api_custom_dir_read_smoke"
)

bash "$safe_root/scripts/run-upstream-shell-tests.sh" \
  --build-dir "$build_root" \
  --test-dir "$safe_root/test" \
  --tests \
    ppm2tiff_pbm.sh \
    ppm2tiff_pgm.sh \
    ppm2tiff_ppm.sh \
    fax2tiff.sh \
    tiffcp-lzw-compat.sh \
    tiffdump.sh \
    tiffinfo.sh \
    tiff2pdf.sh \
    tiff2ps-PS1.sh \
    testfax4.sh \
    testdeflatelaststripextradata.sh
