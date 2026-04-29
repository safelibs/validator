#!/usr/bin/env bash
# @testcase: usage-exif-cli-list-orientation
# @title: exif list orientation
# @description: Lists EXIF metadata for the sample JPEG and verifies the orientation line and decoded value are present.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-list-orientation"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Orientation'
validator_assert_contains "$tmpdir/out" 'Right-top'
