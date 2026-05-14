#!/usr/bin/env bash
# @testcase: usage-exif-r18-cli-extract-thumbnail-explicit-output-trailing-eoi
# @title: exif --extract-thumbnail thumbnail ends with the JPEG EOI marker FFD9
# @description: Extracts the embedded thumbnail from the canon fixture via exif --extract-thumbnail --output=... and asserts the resulting file's final two bytes are the JPEG end-of-image marker FF D9, exercising libexif's thumbnail-blob writeout completeness (distinct from the earlier "starts with FFD8" magic check).
# @timeout: 60
# @tags: usage, exif, thumbnail, eoi, r18
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --extract-thumbnail --output="$tmpdir/thumb.jpg" "$img" >"$tmpdir/log" 2>"$tmpdir/err"
validator_require_file "$tmpdir/thumb.jpg"

size=$(wc -c <"$tmpdir/thumb.jpg")
if [[ "$size" -lt 4 ]]; then
  printf 'thumbnail too small: %s bytes\n' "$size" >&2
  exit 1
fi
eoi=$(tail -c2 "$tmpdir/thumb.jpg" | od -An -tx1 | tr -d ' \n')
if [[ "$eoi" != 'ffd9' ]]; then
  printf 'expected trailing EOI ffd9, got %s\n' "$eoi" >&2
  exit 1
fi
