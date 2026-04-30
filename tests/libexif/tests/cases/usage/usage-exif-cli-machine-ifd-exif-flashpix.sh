#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-ifd-exif-flashpix
# @title: exif --machine-readable --ifd=EXIF emits FlashPixVersion
# @description: Runs the exif client with --machine-readable --ifd=EXIF and verifies the EXIF IFD tab-delimited stream contains FlashPixVersion 1.0 plus other EXIF-IFD tags while excluding the IFD 0 Manufacturer entry.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-ifd-exif-flashpix"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --ifd=EXIF "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" $'FlashPixVersion\tFlashPix Version 1.0'
validator_assert_contains "$tmpdir/out" $'Color Space\tsRGB'
validator_assert_contains "$tmpdir/out" $'Exif Version\tExif Version 2.2'

# Manufacturer belongs to IFD 0 and must not appear when scoped to EXIF IFD
if grep -q '^Manufacturer' "$tmpdir/out"; then
  printf 'unexpected Manufacturer entry in EXIF IFD stream\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
