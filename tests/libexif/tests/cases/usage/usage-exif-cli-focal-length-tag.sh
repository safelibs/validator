#!/usr/bin/env bash
# @testcase: usage-exif-cli-focal-length-tag
# @title: exif focal length tag
# @description: Reads the FocalLength EXIF tag from a JPEG fixture and verifies the focal length text.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-focal-length-tag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=FocalLength "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '5.8 mm'
