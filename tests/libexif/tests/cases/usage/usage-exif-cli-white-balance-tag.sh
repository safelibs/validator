#!/usr/bin/env bash
# @testcase: usage-exif-cli-white-balance-tag
# @title: exif white balance tag
# @description: Reads the WhiteBalance EXIF tag from a JPEG fixture and checks that a value is present.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-white-balance-tag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=WhiteBalance "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Value:'
