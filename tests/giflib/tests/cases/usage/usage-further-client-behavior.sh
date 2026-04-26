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
  usage-giflib-tools-giftext-treescap-background)
    giftext "$samples/treescap.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'BackGround'
    ;;
  usage-giflib-tools-giftext-grid-background)
    giftext "$samples/gifgrid.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'BackGround'
    ;;
  usage-giflib-tools-giftext-treescap-color-resolution)
    giftext "$samples/treescap.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'ColorResolution'
    ;;
  usage-giflib-tools-gif2rgb-treescap-planar)
    gif2rgb -o "$tmpdir/treescap" "$samples/treescap.gif"
    validator_require_file "$tmpdir/treescap.R"
    validator_require_file "$tmpdir/treescap.G"
    validator_require_file "$tmpdir/treescap.B"
    ;;
  usage-giflib-tools-gif2rgb-fire-planar-size)
    gif2rgb -o "$tmpdir/fire" "$samples/fire.gif"
    size_r=$(wc -c <"$tmpdir/fire.R")
    size_g=$(wc -c <"$tmpdir/fire.G")
    size_b=$(wc -c <"$tmpdir/fire.B")
    test "$size_r" -gt 0
    test "$size_r" -eq "$size_g"
    test "$size_g" -eq "$size_b"
    ;;
  usage-giflib-tools-gifbuild-fire-roundtrip-colormap)
    gifbuild -d "$samples/fire.gif" >"$tmpdir/fire.txt"
    gifbuild "$tmpdir/fire.txt" >"$tmpdir/rebuilt.gif"
    gifclrmp "$tmpdir/rebuilt.gif" | tee "$tmpdir/out"
    color_row "$tmpdir/out"
    ;;
  usage-giflib-tools-gifbuild-interlace-flag)
    gifbuild -d "$samples/treescap.gif" >"$tmpdir/plain.txt"
    gifbuild -d "$samples/treescap-interlaced.gif" >"$tmpdir/interlaced.txt"
    if grep -Fq 'image interlaced' "$tmpdir/plain.txt"; then
      printf 'plain treescap dump unexpectedly reported interlacing\n' >&2
      exit 1
    fi
    validator_assert_contains "$tmpdir/interlaced.txt" 'image interlaced'
    ;;
  usage-giflib-tools-giffix-grid-screen)
    giffix "$samples/gifgrid.gif" >"$tmpdir/fixed.gif"
    giftext "$tmpdir/fixed.gif" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Screen Size'
    ;;
  usage-giflib-tools-giffix-treescap-colormap)
    giffix "$samples/treescap.gif" >"$tmpdir/fixed.gif"
    gifclrmp "$tmpdir/fixed.gif" | tee "$tmpdir/out"
    color_row "$tmpdir/out"
    ;;
  usage-giflib-tools-gifclrmp-interlaced)
    gifclrmp "$samples/treescap-interlaced.gif" | tee "$tmpdir/out"
    color_row "$tmpdir/out"
    ;;
  *)
    printf 'unknown giflib further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
