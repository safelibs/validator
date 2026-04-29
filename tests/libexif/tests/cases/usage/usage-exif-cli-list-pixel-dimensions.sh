#!/usr/bin/env bash
# @testcase: usage-exif-cli-list-pixel-dimensions
# @title: exif list pixel dimensions
# @description: Exercises exif list pixel dimensions through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-list-pixel-dimensions"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Pixel X Dimension'
validator_assert_contains "$tmpdir/out" 'Pixel Y Dimension'
