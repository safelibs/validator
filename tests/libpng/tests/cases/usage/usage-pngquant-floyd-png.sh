#!/usr/bin/env bash
# @testcase: usage-pngquant-floyd-png
# @title: pngquant floyd dithering
# @description: Quantizes a PNG fixture with an explicit Floyd dithering value.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-floyd-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

assert_png() {
  file "$1" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
}

pngquant --force --floyd=0.5 --output "$tmpdir/out.png" 16 "$png"
assert_png "$tmpdir/out.png"
