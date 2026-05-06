#!/usr/bin/env bash
# @testcase: usage-exif-r10-cli-tag-max-aperture-value
# @title: exif --tag=MaxApertureValue resolves the APEX maximum aperture
# @description: Runs exif --tag=MaxApertureValue against the canon fixture and verifies the readout names tag id 0x9205 in IFD EXIF, reports the Rational format, and renders the composed 2.97 EV f/2.8 reading libexif derives from the lens APEX maximum aperture rational.
# @timeout: 60
# @tags: usage, metadata, aperture
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=MaxApertureValue "$img" >"$tmpdir/pretty.out"
validator_assert_contains "$tmpdir/pretty.out" "0x9205"
validator_assert_contains "$tmpdir/pretty.out" "MaxApertureValue"
validator_assert_contains "$tmpdir/pretty.out" "IFD 'EXIF'"
validator_assert_contains "$tmpdir/pretty.out" "Format: 5 ('Rational')"
validator_assert_contains "$tmpdir/pretty.out" "f/2.8"

exif --machine-readable --tag=MaxApertureValue "$img" >"$tmpdir/machine.out"
line_count=$(wc -l <"$tmpdir/machine.out")
if (( line_count != 1 )); then
  printf 'expected 1 machine-readable line for MaxApertureValue, got %d\n' "$line_count" >&2
  cat "$tmpdir/machine.out" >&2
  exit 1
fi
grep -Fq 'f/2.8' "$tmpdir/machine.out"
