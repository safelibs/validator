#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-orientation
# @title: exif machine orientation
# @description: Reads the Orientation tag in machine-readable mode and verifies the decoded orientation value.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-orientation"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=Orientation "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Right-top'
