#!/usr/bin/env bash
# @testcase: usage-netpbm-pamfile-png
# @title: netpbm pamfile PNG
# @description: Converts a PNG fixture to PAM and inspects the Netpbm header with pamfile.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pamfile-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

assert_png() {
  file "$1" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
}

pngtopam "$png" >"$tmpdir/in.pam"
pamfile "$tmpdir/in.pam" | tee "$tmpdir/out"
grep -Eq '[0-9]+ by [0-9]+' "$tmpdir/out"
