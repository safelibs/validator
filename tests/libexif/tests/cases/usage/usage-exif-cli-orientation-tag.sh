#!/usr/bin/env bash
# @testcase: usage-exif-cli-orientation-tag
# @title: exif orientation tag
# @description: Reads the Orientation EXIF tag from a JPEG fixture and verifies the reported value.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-orientation-tag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=Orientation "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Right-top'
