#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmgamma-png
# @title: netpbm gamma PNG
# @description: Applies gamma correction to a PNG fixture through Netpbm and writes PNG output.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pnmgamma-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

assert_png() {
  file "$1" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
}

pngtopnm "$png" >"$tmpdir/in.pnm"
pnmgamma 1.8 "$tmpdir/in.pnm" >"$tmpdir/gamma.pnm"
pnmtopng "$tmpdir/gamma.pnm" >"$tmpdir/out.png"
assert_png "$tmpdir/out.png"
