#!/usr/bin/env bash
# @testcase: usage-exif-r10-cli-tag-exposure-bias-value
# @title: exif --tag=ExposureBiasValue surfaces the SRational EV reading
# @description: Runs exif --tag=ExposureBiasValue against the canon fixture and verifies the readout exposes the ExposureBiasValue tag id 0x9204 in IFD EXIF as an SRational reading the composed 0.00 EV value libexif derives from the stored rational.
# @timeout: 60
# @tags: usage, metadata, exposure
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=ExposureBiasValue "$img" >"$tmpdir/pretty.out"
validator_assert_contains "$tmpdir/pretty.out" "0x9204"
validator_assert_contains "$tmpdir/pretty.out" "ExposureBiasValue"
validator_assert_contains "$tmpdir/pretty.out" "IFD 'EXIF'"
validator_assert_contains "$tmpdir/pretty.out" "Format: 10 ('SRational')"
validator_assert_contains "$tmpdir/pretty.out" "0.00 EV"

exif --machine-readable --tag=ExposureBiasValue "$img" >"$tmpdir/machine.out"
line_count=$(wc -l <"$tmpdir/machine.out")
if (( line_count != 1 )); then
  printf 'expected 1 machine-readable line for ExposureBiasValue, got %d\n' "$line_count" >&2
  cat "$tmpdir/machine.out" >&2
  exit 1
fi
grep -Fq '0.00 EV' "$tmpdir/machine.out"
