#!/usr/bin/env bash
# @testcase: usage-exif-cli-list-color-space
# @title: exif list color space
# @description: Exercises exif list color space through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-list-color-space"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Color Space'
validator_assert_contains "$tmpdir/out" 'sRGB'
