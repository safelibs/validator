#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmsmooth-png
# @title: netpbm pnmsmooth PNG
# @description: Smooths a PNG-derived image with pnmsmooth and confirms shape and PNG round-trip.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopnm "$png" >"$tmpdir/in.pnm"
pnmsmooth "$tmpdir/in.pnm" >"$tmpdir/smooth.pnm"

pnmfile "$tmpdir/smooth.pnm" | tee "$tmpdir/info"
validator_assert_contains "$tmpdir/info" '32 by 32'

pnmtopng "$tmpdir/smooth.pnm" >"$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'
