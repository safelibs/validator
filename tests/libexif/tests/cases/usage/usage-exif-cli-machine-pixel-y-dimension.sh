#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-pixel-y-dimension
# @title: exif machine PixelYDimension
# @description: Reads PixelYDimension via exif --machine-readable and verifies the 480 pixel height is reported.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-pixel-y-dimension"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=PixelYDimension "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '480'
