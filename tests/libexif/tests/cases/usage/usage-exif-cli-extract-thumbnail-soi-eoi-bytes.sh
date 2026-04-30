#!/usr/bin/env bash
# @testcase: usage-exif-cli-extract-thumbnail-soi-eoi-bytes
# @title: exif --extract-thumbnail emits a JPEG with SOI and EOI markers
# @description: Extracts the embedded thumbnail from the canon fixture with exif --extract-thumbnail and verifies the file begins with the FFD8FF JPEG SOI marker and ends with the FFD9 JPEG EOI marker, asserting the extracted thumbnail is a complete, framed JPEG rather than a truncated payload.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-extract-thumbnail-soi-eoi-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --extract-thumbnail --output="$tmpdir/thumb.jpg" "$img" >"$tmpdir/extract.log"
validator_assert_contains "$tmpdir/extract.log" 'Wrote file'
validator_require_file "$tmpdir/thumb.jpg"

size=$(stat -c '%s' "$tmpdir/thumb.jpg")
if (( size < 4 )); then
  printf 'thumbnail too small to carry SOI+EOI: size=%d\n' "$size" >&2
  exit 1
fi

# SOI: first three bytes must be FF D8 FF
head -c 3 "$tmpdir/thumb.jpg" | od -An -t x1 | tr -d ' \n' >"$tmpdir/soi"
validator_assert_contains "$tmpdir/soi" 'ffd8ff'

# EOI: last two bytes must be FF D9
tail -c 2 "$tmpdir/thumb.jpg" | od -An -t x1 | tr -d ' \n' >"$tmpdir/eoi"
validator_assert_contains "$tmpdir/eoi" 'ffd9'

# Cross-check via file(1) that this is recognized as JPEG image data
file "$tmpdir/thumb.jpg" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
