#!/usr/bin/env bash
# @testcase: usage-pngquant-verbose-png
# @title: pngquant verbose output
# @description: Quantizes a PNG fixture with verbose logging enabled and verifies PNG output is still produced.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-verbose-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

assert_png() {
  file "$1" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
}

pngquant --verbose --force --output "$tmpdir/out.png" 16 "$png" >"$tmpdir/out.log" 2>&1
assert_png "$tmpdir/out.png"
test -s "$tmpdir/out.log"
