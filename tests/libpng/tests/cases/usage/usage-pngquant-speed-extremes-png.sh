#!/usr/bin/env bash
# @testcase: usage-pngquant-speed-extremes-png
# @title: pngquant speed extremes produce valid PNGs
# @description: Runs pngquant at --speed 1 and --speed 11 against the same input and checks both outputs are valid PNG files with non-zero size.
# @timeout: 240
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --force --speed 1 --output "$tmpdir/slow.png" 256 "$png"
pngquant --force --speed 11 --output "$tmpdir/fast.png" 256 "$png"

for out in "$tmpdir/slow.png" "$tmpdir/fast.png"; do
  test -s "$out"
  file "$out" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
done

slow_size=$(wc -c <"$tmpdir/slow.png")
fast_size=$(wc -c <"$tmpdir/fast.png")
printf 'speed1=%s speed11=%s\n' "$slow_size" "$fast_size"
test "$slow_size" -gt 0
test "$fast_size" -gt 0
