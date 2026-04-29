#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmfile-png
# @title: netpbm pnmfile PNG
# @description: Converts a PNG fixture to PNM and inspects the Netpbm header with pnmfile.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pnmfile-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

assert_png() {
  file "$1" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
}

pngtopnm "$png" >"$tmpdir/in.pnm"
pnmfile "$tmpdir/in.pnm" | tee "$tmpdir/out"
grep -Eq '[0-9]+ by [0-9]+' "$tmpdir/out"
