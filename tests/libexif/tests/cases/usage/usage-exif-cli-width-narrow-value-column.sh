#!/usr/bin/env bash
# @testcase: usage-exif-cli-width-narrow-value-column
# @title: exif --width=40 narrows the value column
# @description: Runs exif --width=40 against the canon fixture and verifies the underline separator row sized for a 40-column terminal contains exactly 30 dashes after the plus sign in the value column, matching libexif default tag-name width plus a 30-character value column for narrow terminals.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-width-narrow-value-column"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --width=40 "$img" >"$tmpdir/out"

# The header table must still be present
validator_assert_contains "$tmpdir/out" "EXIF tags in '$img' ('Intel' byte order):"
validator_assert_contains "$tmpdir/out" 'Tag                 |Value'
validator_assert_contains "$tmpdir/out" 'Manufacturer        |Canon'

# The separator after the '+' must be exactly 30 dashes for width=40
sep=$(grep -m1 -E '^-+\+-+$' "$tmpdir/out")
right=${sep#*+}
if (( ${#right} != 30 )); then
  printf 'expected 30 dashes after + for --width=40, got %d (line: %s)\n' "${#right}" "$sep" >&2
  exit 1
fi
