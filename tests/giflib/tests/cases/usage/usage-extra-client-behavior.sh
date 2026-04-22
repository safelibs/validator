#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-giflib-tools-giftext-fire-header)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
    validator_require_file "$gif"
    giftext "$gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Screen Size'
    ;;
  usage-giflib-tools-giftext-grid-colormap)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
    validator_require_file "$gif"
    giftext -c "$gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Global Color Map'
    ;;
  usage-giflib-tools-gif2rgb-interlaced)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap-interlaced.gif"
    expected="$VALIDATOR_SAMPLE_ROOT/tests/treescap-interlaced.rgb"
    validator_require_file "$gif"
    validator_require_file "$expected"
    gif2rgb -1 -o "$tmpdir/out.rgb" "$gif"
    cmp "$expected" "$tmpdir/out.rgb"
    ;;
  usage-giflib-tools-gif2rgb-grid-planar)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
    validator_require_file "$gif"
    gif2rgb -o "$tmpdir/grid" "$gif"
    validator_require_file "$tmpdir/grid.R"
    validator_require_file "$tmpdir/grid.G"
    validator_require_file "$tmpdir/grid.B"
    wc -c "$tmpdir/grid.R" "$tmpdir/grid.G" "$tmpdir/grid.B"
    ;;
  usage-giflib-tools-gifbuild-fire-roundtrip)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
    validator_require_file "$gif"
    gifbuild -d "$gif" >"$tmpdir/fire.txt"
    gifbuild "$tmpdir/fire.txt" >"$tmpdir/rebuilt.gif"
    giftext "$tmpdir/rebuilt.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Screen Size'
    ;;
  usage-giflib-tools-gifbuild-grid-dump)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
    validator_require_file "$gif"
    gifbuild -d "$gif" >"$tmpdir/dump.txt"
    grep -Ei 'screen|image' "$tmpdir/dump.txt" | tee "$tmpdir/out"
    grep -Eiq 'screen|image' "$tmpdir/out"
    ;;
  usage-giflib-tools-giffix-grid)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
    validator_require_file "$gif"
    giffix "$gif" >"$tmpdir/fixed.gif"
    giftext "$tmpdir/fixed.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Screen Size'
    ;;
  usage-giflib-tools-gifclrmp-fire)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
    validator_require_file "$gif"
    gifclrmp "$gif" | tee "$tmpdir/out"
    grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$tmpdir/out"
    ;;
  usage-giflib-tools-gif2rgb-fire-size)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
    validator_require_file "$gif"
    gif2rgb -1 -o "$tmpdir/fire.rgb" "$gif"
    test "$(wc -c <"$tmpdir/fire.rgb")" -gt 0
    ;;
  usage-giflib-tools-giftext-treescap-images)
    gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
    validator_require_file "$gif"
    giftext "$gif" | tee "$tmpdir/out"
    grep -Eiq 'image' "$tmpdir/out"
    ;;
  *)
    printf 'unknown giflib extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
