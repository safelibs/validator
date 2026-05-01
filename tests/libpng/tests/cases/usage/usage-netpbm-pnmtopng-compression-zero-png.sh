#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmtopng-compression-zero-png
# @title: netpbm pnmtopng -compression 0 vs 9
# @description: Encodes basn2c08.png with pnmtopng -compression 0 (store) and -compression 9 (best) and verifies the compression-0 PNG IDAT stream is materially larger than the compression-9 stream while both decode to identical pixels.
# @timeout: 180
# @tags: usage, image, png, encoding
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopnm "$png" >"$tmpdir/in.ppm"
pnmtopng -compression 0 "$tmpdir/in.ppm" >"$tmpdir/c0.png"
pnmtopng -compression 9 "$tmpdir/in.ppm" >"$tmpdir/c9.png"
file "$tmpdir/c0.png" | tee "$tmpdir/c0.file"
file "$tmpdir/c9.png" | tee "$tmpdir/c9.file"
validator_assert_contains "$tmpdir/c0.file" 'PNG image data'
validator_assert_contains "$tmpdir/c9.file" 'PNG image data'

c0_size=$(stat -c %s "$tmpdir/c0.png")
c9_size=$(stat -c %s "$tmpdir/c9.png")
printf 'compression0=%s compression9=%s\n' "$c0_size" "$c9_size"
if (( c0_size <= c9_size )); then
  printf 'expected -compression 0 to be larger than -compression 9: c0=%s c9=%s\n' "$c0_size" "$c9_size" >&2
  exit 1
fi

# Pixel round-trip equivalence between the two encodings.
pngtopnm "$tmpdir/c0.png" >"$tmpdir/c0.ppm"
pngtopnm "$tmpdir/c9.png" >"$tmpdir/c9.ppm"
cmp "$tmpdir/c0.ppm" "$tmpdir/c9.ppm"
cmp "$tmpdir/c0.ppm" "$tmpdir/in.ppm"
