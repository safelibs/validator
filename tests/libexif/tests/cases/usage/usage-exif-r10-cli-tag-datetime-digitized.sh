#!/usr/bin/env bash
# @testcase: usage-exif-r10-cli-tag-datetime-digitized
# @title: exif --tag=DateTimeDigitized reports the digitization timestamp
# @description: Runs exif --tag=DateTimeDigitized against the canon fixture and verifies the readout names the DateTimeDigitized tag in IFD EXIF, reports the ASCII format, and exposes the 2009:10:10 16:42:32 value byte-exact.
# @timeout: 60
# @tags: usage, metadata, datetime
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=DateTimeDigitized "$img" >"$tmpdir/pretty.out"
validator_assert_contains "$tmpdir/pretty.out" "DateTimeDigitized"
validator_assert_contains "$tmpdir/pretty.out" "IFD 'EXIF'"
validator_assert_contains "$tmpdir/pretty.out" "Format: 2 ('ASCII')"
validator_assert_contains "$tmpdir/pretty.out" "2009:10:10 16:42:32"

exif --machine-readable --tag=DateTimeDigitized "$img" >"$tmpdir/machine.out"
line_count=$(wc -l <"$tmpdir/machine.out")
if (( line_count != 1 )); then
  printf 'expected 1 machine-readable line for DateTimeDigitized, got %d\n' "$line_count" >&2
  cat "$tmpdir/machine.out" >&2
  exit 1
fi
read -r value <"$tmpdir/machine.out"
if [[ "$value" != "2009:10:10 16:42:32" ]]; then
  printf 'unexpected machine value: %s\n' "$value" >&2
  exit 1
fi
