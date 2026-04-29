#!/usr/bin/env bash
# @testcase: usage-exif-cli-list-focal-length
# @title: exif list focal length
# @description: Lists EXIF metadata for the sample JPEG and verifies the focal length line and decoded value are present.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-list-focal-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Focal Length'
validator_assert_contains "$tmpdir/out" '5.8 mm'
