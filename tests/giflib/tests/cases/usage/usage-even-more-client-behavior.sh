#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

case "$case_id" in
  usage-giflib-tools-giftext-fire-color-resolution)
    giftext "$samples/fire.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'ColorResolution'
    ;;
  usage-giflib-tools-giftext-fire-background)
    giftext "$samples/fire.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'BackGround'
    ;;
  usage-giflib-tools-giftext-treescap-colormap)
    giftext -c "$samples/treescap.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Global Color Map'
    ;;
  usage-giflib-tools-giftext-interlaced-colormap)
    giftext -c "$samples/treescap-interlaced.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Global Color Map'
    ;;
  usage-giflib-tools-gif2rgb-fire-compare)
    gif2rgb -1 -o "$tmpdir/fire.rgb" "$samples/fire.gif"
    cmp "$tests_root/fire.rgb" "$tmpdir/fire.rgb"
    ;;
  usage-giflib-tools-gif2rgb-interlaced-planar)
    gif2rgb -o "$tmpdir/interlaced" "$samples/treescap-interlaced.gif"
    validator_require_file "$tmpdir/interlaced.R"
    validator_require_file "$tmpdir/interlaced.G"
    validator_require_file "$tmpdir/interlaced.B"
    test "$(wc -c <"$tmpdir/interlaced.R")" -gt 0
    ;;
  usage-giflib-tools-gifbuild-interlaced-dump)
    gifbuild -d "$samples/treescap-interlaced.gif" >"$tmpdir/dump.txt"
    grep -Eiq 'screen|image' "$tmpdir/dump.txt"
    ;;
  usage-giflib-tools-gifbuild-grid-roundtrip-colormap)
    gifbuild -d "$samples/gifgrid.gif" >"$tmpdir/grid.txt"
    gifbuild "$tmpdir/grid.txt" >"$tmpdir/grid.gif"
    gifclrmp "$tmpdir/grid.gif" | tee "$tmpdir/out"
    grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$tmpdir/out"
    ;;
  usage-giflib-tools-giffix-fire-giftext)
    giffix "$samples/treescap.gif" >"$tmpdir/fixed.gif"
    giftext "$tmpdir/fixed.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Image'
    ;;
  usage-giflib-tools-giffix-interlaced-colormap)
    giffix "$samples/gifgrid.gif" >"$tmpdir/fixed.gif"
    gifclrmp "$tmpdir/fixed.gif" | tee "$tmpdir/out"
    grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$tmpdir/out"
    ;;
  *)
    printf 'unknown giflib even-more usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
