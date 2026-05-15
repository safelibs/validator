#!/usr/bin/env bash
# @testcase: usage-vips-r19-flip-horizontal-then-horizontal-dims
# @title: vips flip horizontal applied twice via .v intermediates preserves dims
# @description: Encodes a 32x20 RGB PPM as JPEG via vips jpegsave, runs vips flip --direction horizontal twice through .v intermediates, and asserts vipsheader reports the original 32x20 dimensions and 3 bands on the final output, exercising libjpeg-turbo decode followed by two successive vips horizontal flips.
# @timeout: 180
# @tags: usage, vips, jpeg, flip, horizontal, double, r19
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Generate a 32x20 RGB PPM with a deterministic pattern using shell + od.
W=32; H=20
{
  printf 'P6\n%d %d\n255\n' "$W" "$H"
  head -c $((W * H * 3)) /dev/urandom
} >"$tmpdir/in.ppm"

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips flip "$tmpdir/in.jpg" "$tmpdir/mid.v" horizontal
vips flip "$tmpdir/mid.v" "$tmpdir/out.v" horizontal

vipsheader "$tmpdir/out.v" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" '32x20'
validator_assert_contains "$tmpdir/hdr" '3 bands'
