#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-color-space-ids-hex
# @title: exif --ids --tag=ColorSpace reports 0xa001
# @description: Runs the exif client with --ids --tag=ColorSpace against the canon fixture and verifies the EXIF tag id for ColorSpace is reported as 0xa001 alongside the symbolic name and the sRGB value, asserting the numeric id and decoded value live on the same readout.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-color-space-ids-hex"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ids --tag=ColorSpace "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "Tag: 0xa001 ('ColorSpace')"
validator_assert_contains "$tmpdir/out" 'Value: sRGB'

# The decoded value must coexist with the hex id on the same readout
if ! grep -q '0xa001' "$tmpdir/out"; then
  printf 'expected hex id 0xa001 for ColorSpace\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
