#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-color-space
# @title: exif machine color space
# @description: Reads the ColorSpace tag in machine-readable mode and verifies the decoded colorspace value.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-color-space"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=ColorSpace "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'sRGB'
