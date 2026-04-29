#!/usr/bin/env bash
# @testcase: usage-netpbm-pamtopnm-roundtrip-png
# @title: netpbm PAM to PNM round trip
# @description: Converts a PNG fixture through PAM and PNM formats before writing PNG output.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pamtopnm-roundtrip-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

assert_png() {
  file "$1" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
}

pngtopam "$png" >"$tmpdir/in.pam"
pamtopnm "$tmpdir/in.pam" >"$tmpdir/out.pnm"
pnmtopng "$tmpdir/out.pnm" >"$tmpdir/out.png"
assert_png "$tmpdir/out.png"
