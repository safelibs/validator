#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-pixel-y-sed
# @title: exif tag pixel y via sed
# @description: Extracts the exif PixelYDimension tag value through shell text processing and verifies the parsed height.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-pixel-y-sed"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

extract_value() {
  sed -n 's/.*Value: //p' "$1" >"$tmpdir/value"
  test -s "$tmpdir/value"
}

exif --tag=PixelYDimension "$img" >"$tmpdir/out"
extract_value "$tmpdir/out"
validator_assert_contains "$tmpdir/value" '480'
