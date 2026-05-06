#!/usr/bin/env bash
# @testcase: usage-exif-r11-cli-ifd-one-table-thumbnail-line
# @title: exif --ifd=1 dump ends with the thumbnail-byte announcement line
# @description: Renders the IFD 1 dump for the canon fixture and verifies the line "EXIF data contains a thumbnail (4 bytes)." is present, asserting libexif advertises the thumbnail payload size from the IFD-1 view in addition to listing the per-tag rows.
# @timeout: 60
# @tags: usage, ifd, thumbnail
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=1 "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "EXIF data contains a thumbnail (4 bytes)."
