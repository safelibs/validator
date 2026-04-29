#!/usr/bin/env bash
# @testcase: usage-exif-cli-pixel-dimensions
# @title: exif pixel dimensions
# @description: Reads EXIF pixel dimension tags from a JPEG fixture.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-pixel-dimensions"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=PixelXDimension "$img" | tee "$tmpdir/x"
exif --tag=PixelYDimension "$img" | tee "$tmpdir/y"
validator_assert_contains "$tmpdir/x" 'Value:'
validator_assert_contains "$tmpdir/y" 'Value:'
