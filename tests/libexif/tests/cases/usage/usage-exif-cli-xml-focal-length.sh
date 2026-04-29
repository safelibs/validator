#!/usr/bin/env bash
# @testcase: usage-exif-cli-xml-focal-length
# @title: exif XML focal length
# @description: Exercises exif xml focal length through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-xml-focal-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '<Focal_Length>5.8 mm</Focal_Length>'
