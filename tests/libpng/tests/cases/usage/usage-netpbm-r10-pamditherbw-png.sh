#!/usr/bin/env bash
# @testcase: usage-netpbm-r10-pamditherbw-png
# @title: netpbm pamditherbw produces a 1-bit raster from a PNG-derived grayscale image
# @description: Decodes a PNG with a 4-step grayscale ramp through pngtopnm, runs pamditherbw, and verifies the output declares 1 BLACKANDWHITE channel via pamfile.
# @timeout: 180
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'P2\n4 1\n255\n0 64 192 255\n' >"$tmpdir/in.pgm"
pnmtopng "$tmpdir/in.pgm" >"$tmpdir/in.png"
pngtopnm "$tmpdir/in.png" | pamditherbw >"$tmpdir/out.pam"

pamfile "$tmpdir/out.pam" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'BLACKANDWHITE'
validator_assert_contains "$tmpdir/out.txt" '4 by 1'
