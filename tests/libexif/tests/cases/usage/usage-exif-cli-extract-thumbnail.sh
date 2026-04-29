#!/usr/bin/env bash
# @testcase: usage-exif-cli-extract-thumbnail
# @title: exif CLI thumbnail extraction
# @description: Runs the exif CLI to extract the embedded JPEG thumbnail from camera metadata.
# @timeout: 180
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="extract-thumbnail"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --extract-thumbnail --output="$tmpdir/thumb.jpg" "$img"
file "$tmpdir/thumb.jpg" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'JPEG image data'
