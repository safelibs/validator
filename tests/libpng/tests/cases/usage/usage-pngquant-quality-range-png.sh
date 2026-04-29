#!/usr/bin/env bash
# @testcase: usage-pngquant-quality-range-png
# @title: pngquant quality range
# @description: Quantizes a PNG fixture with a quality range constraint and verifies PNG output.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-quality-range-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

assert_png() {
  file "$1" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
}

pngquant --force --quality=40-80 --output "$tmpdir/out.png" 32 "$png"
assert_png "$tmpdir/out.png"
