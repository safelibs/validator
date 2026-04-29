#!/usr/bin/env bash
# @testcase: usage-netpbm-pamchannel-blue-png
# @title: netpbm blue channel PNG
# @description: Extracts the blue channel from a PNG fixture through Netpbm PAM tools.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pamchannel-blue-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

assert_png() {
  file "$1" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
}

pngtopam "$png" >"$tmpdir/in.pam"
pamchannel -infile="$tmpdir/in.pam" 2 >"$tmpdir/blue.pam"
pamfile "$tmpdir/blue.pam" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'by 1 maxval 255'
