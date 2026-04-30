#!/usr/bin/env bash
# @testcase: usage-netpbm-pbmtoxbm-bilevel-png
# @title: netpbm pbmtoxbm bilevel via threshold
# @description: Thresholds a PNG-derived grayscale image to bilevel PBM and converts it to an X bitmap, verifying the XBM C header.
# @timeout: 180
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a deterministic 4x1 grayscale gradient PNG.
printf 'P2\n4 1\n255\n0 80 180 255\n' >"$tmpdir/in.pgm"
pnmtopng "$tmpdir/in.pgm" >"$tmpdir/in.png"

pngtopnm "$tmpdir/in.png" >"$tmpdir/raw.pgm"

# Threshold to bilevel PBM, then convert to XBM.
pamthreshold "$tmpdir/raw.pgm" | pamtopnm >"$tmpdir/bw.pbm"
file "$tmpdir/bw.pbm" | tee "$tmpdir/file-pbm"
validator_assert_contains "$tmpdir/file-pbm" 'Netpbm'

pbmtoxbm "$tmpdir/bw.pbm" >"$tmpdir/out.xbm"

# XBM is a C header with #define width and a static char[] array.
validator_assert_contains "$tmpdir/out.xbm" '#define'
validator_assert_contains "$tmpdir/out.xbm" '_width 4'
validator_assert_contains "$tmpdir/out.xbm" '_height 1'
validator_assert_contains "$tmpdir/out.xbm" 'static'
validator_assert_contains "$tmpdir/out.xbm" '0x'

# Round-trip back to PBM and confirm dimensions.
xbmtopbm "$tmpdir/out.xbm" >"$tmpdir/back.pbm"
pamfile "$tmpdir/back.pbm" | tee "$tmpdir/back-info"
validator_assert_contains "$tmpdir/back-info" '4 by 1'
