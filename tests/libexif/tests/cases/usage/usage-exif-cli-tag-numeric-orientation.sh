#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-numeric-orientation
# @title: exif --tag=0x0112 numeric Orientation lookup
# @description: Looks up the Orientation tag by its numeric tag id 0x0112 instead of by name and verifies the canon fixture reports the Orientation entry with value Right-top, then cross-checks the same record against a name-based --tag=Orientation lookup to confirm the two produce equivalent metadata.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-numeric-orientation"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=0x0112 "$img" >"$tmpdir/numeric.out"
validator_assert_contains "$tmpdir/numeric.out" "EXIF entry 'Orientation'"
validator_assert_contains "$tmpdir/numeric.out" 'Value: Right-top'

# Confirm a name-based lookup yields the same entry; both runs must report the
# same Orientation tag header and value.
exif --tag=Orientation "$img" >"$tmpdir/named.out"
validator_assert_contains "$tmpdir/named.out" "EXIF entry 'Orientation'"
validator_assert_contains "$tmpdir/named.out" 'Value: Right-top'

# The Right-top value line must appear identically in both outputs
grep -F 'Value: Right-top' "$tmpdir/numeric.out" >"$tmpdir/numeric.value"
grep -F 'Value: Right-top' "$tmpdir/named.out" >"$tmpdir/named.value"
if ! cmp -s "$tmpdir/numeric.value" "$tmpdir/named.value"; then
  printf 'numeric and named --tag readbacks disagree on Orientation value line\n' >&2
  diff -u "$tmpdir/named.value" "$tmpdir/numeric.value" >&2 || true
  exit 1
fi
