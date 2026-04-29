#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

require_nonempty() {
  test "$(wc -c <"$1")" -gt 0
}

case "$case_id" in
  usage-giflib-tools-batch11-fire-image-marker)
    giftext "$samples/fire.gif" | tee "$tmpdir/out"
    grep -Eq 'Image #[0-9]+' "$tmpdir/out"
    ;;
  usage-giflib-tools-batch11-grid-screen-size)
    giftext "$samples/gifgrid.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Screen Size - Width'
    ;;
  usage-giflib-tools-batch11-treescap-rgb-nonempty)
    gif2rgb -1 -o "$tmpdir/tree.rgb" "$samples/treescap.gif"
    require_nonempty "$tmpdir/tree.rgb"
    ;;
  usage-giflib-tools-batch11-grid-rgb-nonempty)
    gif2rgb -1 -o "$tmpdir/grid.rgb" "$samples/gifgrid.gif"
    require_nonempty "$tmpdir/grid.rgb"
    ;;
  usage-giflib-tools-batch11-fire-planar-same-size)
    gif2rgb -o "$tmpdir/fire" "$samples/fire.gif"
    size_r=$(wc -c <"$tmpdir/fire.R")
    size_g=$(wc -c <"$tmpdir/fire.G")
    size_b=$(wc -c <"$tmpdir/fire.B")
    test "$size_r" -gt 0
    test "$size_r" -eq "$size_g"
    test "$size_g" -eq "$size_b"
    ;;
  usage-giflib-tools-batch11-gifbuild-fire-rgb-compare)
    gifbuild -d "$samples/fire.gif" >"$tmpdir/fire.txt"
    gifbuild "$tmpdir/fire.txt" >"$tmpdir/rebuilt.gif"
    gif2rgb -1 -o "$tmpdir/rebuilt.rgb" "$tmpdir/rebuilt.gif"
    cmp "$tests_root/fire.rgb" "$tmpdir/rebuilt.rgb"
    ;;
  usage-giflib-tools-batch11-giffix-grid-rgb-output)
    giffix "$samples/gifgrid.gif" >"$tmpdir/fixed.gif"
    gif2rgb -1 -o "$tmpdir/fixed.rgb" "$tmpdir/fixed.gif"
    require_nonempty "$tmpdir/fixed.rgb"
    ;;
  usage-giflib-tools-batch11-gifclrmp-treescap-row-count)
    gifclrmp "$samples/treescap.gif" >"$tmpdir/map.txt"
    test "$(grep -Ec '^[[:space:]]*[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$tmpdir/map.txt")" -gt 1
    ;;
  usage-giflib-tools-batch11-interlaced-image-marker)
    giftext "$samples/treescap-interlaced.gif" | tee "$tmpdir/out"
    grep -Eq 'Image #[0-9]+' "$tmpdir/out"
    ;;
  usage-giflib-tools-batch11-grid-build-dump-size)
    gifbuild -d "$samples/gifgrid.gif" >"$tmpdir/grid.txt"
    require_nonempty "$tmpdir/grid.txt"
    validator_assert_contains "$tmpdir/grid.txt" 'screen'
    ;;
  *)
    printf 'unknown giflib eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
