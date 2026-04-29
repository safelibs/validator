#!/usr/bin/env bash
# @testcase: usage-exif-cli-thumbnail-size
# @title: exif extracted thumbnail size
# @description: Extracts a thumbnail from a JPEG fixture and checks it is nonempty.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-thumbnail-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --extract-thumbnail --output="$tmpdir/thumb.jpg" "$img"
validator_require_file "$tmpdir/thumb.jpg"
test "$(wc -c <"$tmpdir/thumb.jpg")" -gt 0
