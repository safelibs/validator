#!/usr/bin/env bash
# @testcase: usage-vips-r19-extract-area-quadrant-dims
# @title: vips extract_area cropping the top-left quadrant of a JPEG yields half dims
# @description: Encodes a 40x24 RGB PPM as JPEG via vips jpegsave, runs vips extract_area to crop the top-left 20x12 region into a .v intermediate, and asserts vipsheader reports the cropped dimensions 20x12 and 3 bands on the result, exercising libjpeg-turbo decode followed by vips extract_area on a fixed rectangle.
# @timeout: 180
# @tags: usage, vips, jpeg, extract-area, crop, r19
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

W=40; H=24
{
  printf 'P6\n%d %d\n255\n' "$W" "$H"
  head -c $((W * H * 3)) /dev/urandom
} >"$tmpdir/in.ppm"

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips extract_area "$tmpdir/in.jpg" "$tmpdir/crop.v" 0 0 20 12
vipsheader "$tmpdir/crop.v" >"$tmpdir/hdr"

validator_assert_contains "$tmpdir/hdr" '20x12'
validator_assert_contains "$tmpdir/hdr" '3 bands'
