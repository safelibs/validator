#!/usr/bin/env bash
# @testcase: usage-vips-r19-vipsheader-rgb-jpeg-three-bands
# @title: vipsheader on a 24x16 RGB JPEG reports 24x16 and 3 bands
# @description: Encodes a 24x16 RGB PPM as JPEG via vips jpegsave, runs vipsheader on the resulting JPEG, and asserts the captured header line contains the literal "24x16" dimensions token and the "3 bands" band-count token, exercising libjpeg-turbo decode through vipsheader's metadata report on an RGB fixture.
# @timeout: 180
# @tags: usage, vips, vipsheader, jpeg, rgb, r19
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

W=24; H=16
{
  printf 'P6\n%d %d\n255\n' "$W" "$H"
  head -c $((W * H * 3)) /dev/urandom
} >"$tmpdir/in.ppm"

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vipsheader "$tmpdir/in.jpg" >"$tmpdir/hdr"

validator_assert_contains "$tmpdir/hdr" '24x16'
validator_assert_contains "$tmpdir/hdr" '3 bands'
