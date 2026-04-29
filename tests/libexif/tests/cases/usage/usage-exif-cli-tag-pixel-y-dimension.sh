#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-pixel-y-dimension
# @title: exif pixel Y dimension tag
# @description: Reads the PixelYDimension tag and verifies the reported vertical pixel dimension.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-pixel-y-dimension"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=PixelYDimension "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '480'
