#!/usr/bin/env bash
# @testcase: usage-exif-cli-exposure-time
# @title: exif exposure time tag
# @description: Reads the ExposureTime EXIF tag from a JPEG fixture.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-exposure-time"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=ExposureTime "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Value:'
