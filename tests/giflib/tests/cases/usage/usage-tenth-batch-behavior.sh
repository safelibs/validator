#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

case "$case_id" in
  usage-giflib-tools-giftext-grid-color-map)
    giftext -c "$samples/gifgrid.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Global Color Map'
    ;;
  usage-giflib-tools-giftext-fire-bits-per-pixel)
    giftext "$samples/fire.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'BitsPerPixel'
    ;;
  usage-giflib-tools-giftext-treescap-bits-per-pixel)
    giftext "$samples/treescap.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'BitsPerPixel'
    ;;
  usage-giflib-tools-giftext-interlaced-bits-per-pixel)
    giftext "$samples/treescap-interlaced.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'BitsPerPixel'
    ;;
  usage-giflib-tools-gif2rgb-grid-planar-equal-channels)
    gif2rgb -o "$tmpdir/grid" "$samples/gifgrid.gif"
    validator_require_file "$tmpdir/grid.R"
    validator_require_file "$tmpdir/grid.G"
    validator_require_file "$tmpdir/grid.B"
    size_r=$(wc -c <"$tmpdir/grid.R")
    size_g=$(wc -c <"$tmpdir/grid.G")
    size_b=$(wc -c <"$tmpdir/grid.B")
    test "$size_r" -gt 0
    test "$size_r" -eq "$size_g"
    test "$size_g" -eq "$size_b"
    ;;
  usage-giflib-tools-gif2rgb-treescap-rgb-compare)
    gif2rgb -1 -o "$tmpdir/interlaced.rgb" "$samples/treescap-interlaced.gif"
    cmp "$tests_root/treescap-interlaced.rgb" "$tmpdir/interlaced.rgb"
    ;;
  usage-giflib-tools-gifbuild-fire-roundtrip-screen-size)
    gifbuild -d "$samples/fire.gif" >"$tmpdir/fire.txt"
    gifbuild "$tmpdir/fire.txt" >"$tmpdir/rebuilt.gif"
    giftext "$tmpdir/rebuilt.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Screen Size'
    ;;
  usage-giflib-tools-gifbuild-treescap-roundtrip-colormap)
    gifbuild -d "$samples/treescap.gif" >"$tmpdir/tree.txt"
    gifbuild "$tmpdir/tree.txt" >"$tmpdir/rebuilt.gif"
    gifclrmp "$tmpdir/rebuilt.gif" | tee "$tmpdir/out"
    color_row "$tmpdir/out"
    ;;
  usage-giflib-tools-giffix-fire-screen-size)
    giffix "$samples/treescap.gif" >"$tmpdir/fixed.gif"
    giftext "$tmpdir/fixed.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Screen Size'
    ;;
  usage-giflib-tools-gifclrmp-grid-palette-row)
    gifclrmp "$samples/gifgrid.gif" | tee "$tmpdir/out"
    color_row "$tmpdir/out"
    ;;
  *)
    printf 'unknown giflib tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
