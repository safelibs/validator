#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmflip-png
# @title: netpbm flips PNG
# @description: Converts and flips a PNG fixture with Netpbm before writing PNG output.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pnmflip-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

assert_png() {
  file "$1" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
}

pngtopnm "$png" >"$tmpdir/in.pnm"
pnmflip -leftright "$tmpdir/in.pnm" >"$tmpdir/flipped.pnm"
pnmtopng "$tmpdir/flipped.pnm" >"$tmpdir/out.png"
assert_png "$tmpdir/out.png"
