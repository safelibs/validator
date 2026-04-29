#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-pixel-x-dimension
# @title: exif pixel X dimension tag
# @description: Reads the PixelXDimension tag and verifies the reported horizontal pixel dimension.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-pixel-x-dimension"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=PixelXDimension "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '640'
