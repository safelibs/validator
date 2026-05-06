#!/usr/bin/env bash
# @testcase: usage-exif-r10-cli-tag-compressed-bits-per-pixel
# @title: exif --tag=CompressedBitsPerPixel reports the Rational JPEG bit budget
# @description: Runs exif --tag=CompressedBitsPerPixel against the canon fixture and verifies the readout names tag id 0x9102 in IFD EXIF, reports the Rational format with one component and 8-byte size, and exposes the bits-per-pixel scalar libexif decodes from the stored rational.
# @timeout: 60
# @tags: usage, metadata, jpeg
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=CompressedBitsPerPixel "$img" >"$tmpdir/pretty.out"
validator_assert_contains "$tmpdir/pretty.out" "0x9102"
validator_assert_contains "$tmpdir/pretty.out" "CompressedBitsPerPixel"
validator_assert_contains "$tmpdir/pretty.out" "IFD 'EXIF'"
validator_assert_contains "$tmpdir/pretty.out" "Format: 5 ('Rational')"
validator_assert_contains "$tmpdir/pretty.out" "Components: 1"
validator_assert_contains "$tmpdir/pretty.out" "Size: 8"
validator_assert_contains "$tmpdir/pretty.out" "Value:"

# The composed value should contain a digit; the canon fixture renders " 5"
if ! grep -E "Value:[[:space:]]+[0-9]" "$tmpdir/pretty.out" >/dev/null; then
  printf 'expected numeric Value: line\n' >&2
  cat "$tmpdir/pretty.out" >&2
  exit 1
fi
