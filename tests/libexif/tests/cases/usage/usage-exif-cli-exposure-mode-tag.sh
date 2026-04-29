#!/usr/bin/env bash
# @testcase: usage-exif-cli-exposure-mode-tag
# @title: exif exposure mode tag
# @description: Reads the ExposureMode EXIF tag from a JPEG fixture.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-exposure-mode-tag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=ExposureMode "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Auto exposure'
