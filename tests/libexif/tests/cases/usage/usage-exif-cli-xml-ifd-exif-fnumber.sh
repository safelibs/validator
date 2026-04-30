#!/usr/bin/env bash
# @testcase: usage-exif-cli-xml-ifd-exif-fnumber
# @title: exif --xml-output --ifd=EXIF emits F-Number element
# @description: Runs the exif client with --xml-output --ifd=EXIF against the canon fixture and verifies the EXIF-IFD scoped XML stream wraps the F-Number element with f/2.8 alongside Exposure_Time and Color_Space, and excludes the IFD 0 Manufacturer element.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-xml-ifd-exif-fnumber"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output --ifd=EXIF "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '<exif>'
validator_assert_contains "$tmpdir/out" '</exif>'
validator_assert_contains "$tmpdir/out" '<F-Number>f/2.8</F-Number>'
validator_assert_contains "$tmpdir/out" '<Exposure_Time>1 sec.</Exposure_Time>'
validator_assert_contains "$tmpdir/out" '<Color_Space>sRGB</Color_Space>'

# Manufacturer is an IFD 0 tag and must not appear under --ifd=EXIF
if grep -q 'Manufacturer' "$tmpdir/out"; then
  printf 'unexpected Manufacturer element in EXIF IFD XML\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
