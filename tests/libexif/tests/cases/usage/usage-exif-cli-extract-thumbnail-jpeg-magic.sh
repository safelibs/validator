#!/usr/bin/env bash
# @testcase: usage-exif-cli-extract-thumbnail-jpeg-magic
# @title: exif extracted thumbnail JPEG magic
# @description: Extracts the embedded thumbnail with exif --extract-thumbnail and verifies the output begins with the FFD8FF JPEG SOI marker.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-extract-thumbnail-jpeg-magic"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --extract-thumbnail --output="$tmpdir/thumb.jpg" "$img"
validator_require_file "$tmpdir/thumb.jpg"
head -c 3 "$tmpdir/thumb.jpg" | od -An -t x1 | tr -d ' \n' >"$tmpdir/magic"
validator_assert_contains "$tmpdir/magic" 'ffd8ff'
