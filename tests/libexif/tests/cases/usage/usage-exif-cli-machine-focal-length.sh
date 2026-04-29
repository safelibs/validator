#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-focal-length
# @title: exif machine focal length
# @description: Reads the FocalLength tag in machine-readable mode and verifies the decoded focal length value.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-focal-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=FocalLength "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '5.8 mm'
