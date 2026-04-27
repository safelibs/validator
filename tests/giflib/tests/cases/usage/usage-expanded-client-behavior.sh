#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

case "$case_id" in
  usage-giflib-tools-giftext-fire-screen-size)
    giftext "$samples/fire.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Screen Size'
    ;;
  usage-giflib-tools-giftext-fire-colormap-row)
    giftext -c "$samples/fire.gif" | tee "$tmpdir/out"
    grep -Eq '^[[:space:]]*0:' "$tmpdir/out"
    ;;
  usage-giflib-tools-giftext-grid-bits-per-pixel)
    giftext "$samples/gifgrid.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'BitsPerPixel'
    ;;
  usage-giflib-tools-gif2rgb-fire-rgb-bytes)
    gif2rgb -1 -o "$tmpdir/fire.rgb" "$samples/fire.gif"
    test "$(wc -c <"$tmpdir/fire.rgb")" -gt 0
    ;;
  usage-giflib-tools-gif2rgb-interlaced-rgb-bytes)
    gif2rgb -1 -o "$tmpdir/interlaced.rgb" "$samples/treescap-interlaced.gif"
    test "$(wc -c <"$tmpdir/interlaced.rgb")" -gt 0
    ;;
  usage-giflib-tools-gifbuild-grid-roundtrip-screen)
    gifbuild -d "$samples/gifgrid.gif" >"$tmpdir/grid.txt"
    gifbuild "$tmpdir/grid.txt" >"$tmpdir/grid.gif"
    giftext "$tmpdir/grid.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Screen Size'
    ;;
  usage-giflib-tools-gifbuild-treescap-roundtrip-screen)
    gifbuild -d "$samples/treescap.gif" >"$tmpdir/tree.txt"
    gifbuild "$tmpdir/tree.txt" >"$tmpdir/tree.gif"
    giftext "$tmpdir/tree.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Screen Size'
    ;;
  usage-giflib-tools-giffix-treescap-screen-size)
    giffix "$samples/treescap.gif" >"$tmpdir/fixed.gif"
    giftext "$tmpdir/fixed.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Screen Size'
    ;;
  usage-giflib-tools-gifclrmp-fire-palette-row)
    gifclrmp "$samples/fire.gif" | tee "$tmpdir/out"
    color_row "$tmpdir/out"
    ;;
  usage-giflib-tools-giftext-interlaced-screen-size)
    giftext "$samples/treescap-interlaced.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Screen Size'
    ;;
  *)
    printf 'unknown giflib expanded usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
