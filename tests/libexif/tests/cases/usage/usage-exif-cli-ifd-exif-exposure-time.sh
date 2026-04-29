#!/usr/bin/env bash
# @testcase: usage-exif-cli-ifd-exif-exposure-time
# @title: exif IFD EXIF exposure time
# @description: Exercises exif ifd exif exposure time through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-ifd-exif-exposure-time"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=EXIF "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Exposure Time'
