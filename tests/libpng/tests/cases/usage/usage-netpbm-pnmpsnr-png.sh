#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmpsnr-png
# @title: netpbm pnmpsnr PNG comparison
# @description: Compares a PNG against itself with pnmpsnr and verifies an identical-image report.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopnm "$png" >"$tmpdir/a.pnm"
cp "$tmpdir/a.pnm" "$tmpdir/b.pnm"

# pnmpsnr writes its report to stderr; merge to stdout for inspection.
pnmpsnr "$tmpdir/a.pnm" "$tmpdir/b.pnm" >"$tmpdir/out" 2>&1 || true
cat "$tmpdir/out"
# Ubuntu 24.04 netpbm reports byte-identical channels as "no difference"
# rather than a numeric PSNR or the literal "identical".
validator_assert_contains "$tmpdir/out" 'no difference'
