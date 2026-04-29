#!/usr/bin/env bash
# @testcase: usage-pngquant-colors-eight-png
# @title: pngquant eight colors
# @description: Quantizes a PNG fixture to eight colors and verifies PNG output.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-colors-eight-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

assert_png() {
  file "$1" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
}

pngquant --force --output "$tmpdir/out.png" 8 "$png"
assert_png "$tmpdir/out.png"
