#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-giflib-tools-giftext-fire-image-count)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
    validator_require_file "$gif"
    giftext "$gif" | tee "$tmpdir/out"
    grep -Eiq 'image|Image' "$tmpdir/out"
    ;;
  usage-giflib-tools-giftext-grid-color-resolution)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
    validator_require_file "$gif"
    giftext "$gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'ColorResolution'
    ;;
  usage-giflib-tools-gif2rgb-treescap-rgb-size)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
    validator_require_file "$gif"
    gif2rgb -1 -o "$tmpdir/treescap.rgb" "$gif"
    test "$(wc -c <"$tmpdir/treescap.rgb")" -gt 0
    ;;
  usage-giflib-tools-gif2rgb-grid-planar-size)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
    validator_require_file "$gif"
    gif2rgb -o "$tmpdir/grid" "$gif"
    size_r=$(wc -c <"$tmpdir/grid.R")
    size_g=$(wc -c <"$tmpdir/grid.G")
    size_b=$(wc -c <"$tmpdir/grid.B")
    test "$size_r" -gt 0
    test "$size_r" -eq "$size_g"
    test "$size_g" -eq "$size_b"
    ;;
  usage-giflib-tools-gifbuild-fire-dump-lines)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
    validator_require_file "$gif"
    gifbuild -d "$gif" >"$tmpdir/dump.txt"
    test "$(wc -l <"$tmpdir/dump.txt")" -gt 0
    ;;
  usage-giflib-tools-gifbuild-interlaced-roundtrip)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap-interlaced.gif"
    validator_require_file "$gif"
    gifbuild -d "$gif" >"$tmpdir/interlaced.txt"
    gifbuild "$tmpdir/interlaced.txt" >"$tmpdir/rebuilt.gif"
    giftext "$tmpdir/rebuilt.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Screen Size'
    ;;
  usage-giflib-tools-giffix-interlaced)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap-interlaced.gif"
    validator_require_file "$gif"
    if giffix "$gif" >"$tmpdir/fixed.gif" 2>"$tmpdir/err"; then
      printf 'giffix unexpectedly accepted interlaced fixture\n' >&2
      exit 1
    fi
    validator_assert_contains "$tmpdir/err" 'Cannot fix interlaced images'
    ;;
  usage-giflib-tools-gifclrmp-treescap)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
    validator_require_file "$gif"
    gifclrmp "$gif" | tee "$tmpdir/out"
    grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$tmpdir/out"
    ;;
  usage-giflib-tools-giftext-fire-color-count)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
    validator_require_file "$gif"
    giftext -c "$gif" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Global Color Map'
    ;;
  usage-giflib-tools-gifbuild-grid-roundtrip)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
    validator_require_file "$gif"
    gifbuild -d "$gif" >"$tmpdir/grid.txt"
    gifbuild "$tmpdir/grid.txt" >"$tmpdir/rebuilt.gif"
    giftext "$tmpdir/rebuilt.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Screen Size'
    ;;
  *)
    printf 'unknown giflib additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
