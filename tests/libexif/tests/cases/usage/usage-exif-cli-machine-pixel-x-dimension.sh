#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-pixel-x-dimension
# @title: exif machine PixelXDimension
# @description: Reads PixelXDimension via exif --machine-readable and verifies the 640 pixel width is reported.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-pixel-x-dimension"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=PixelXDimension "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '640'
