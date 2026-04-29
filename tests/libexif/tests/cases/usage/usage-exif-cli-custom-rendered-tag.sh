#!/usr/bin/env bash
# @testcase: usage-exif-cli-custom-rendered-tag
# @title: exif custom rendered tag
# @description: Reads the CustomRendered EXIF tag from a JPEG fixture.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-custom-rendered-tag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=CustomRendered "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Normal process'
