#!/usr/bin/env bash
# @testcase: usage-exif-cli-width-wide-value-column
# @title: exif --width=120 widens the value column
# @description: Runs exif --width=120 against the canon fixture and verifies the value-column separator row is exactly 98 dashes wide so wide terminals receive a stretched table while the narrow 40-column run still fits in 30 dashes, exposing the WIDTH parameter scaling factor for the table renderer.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-width-wide-value-column"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --width=120 "$img" >"$tmpdir/wide.out"
exif --width=40 "$img" >"$tmpdir/narrow.out"

# Wide separator
wide_sep=$(grep -m1 -E '^-+\+-+$' "$tmpdir/wide.out")
wide_right=${wide_sep#*+}
if (( ${#wide_right} != 98 )); then
  printf 'expected 98 dashes after + for --width=120, got %d (line: %s)\n' "${#wide_right}" "$wide_sep" >&2
  exit 1
fi

# Narrow separator must be different (30) - confirms width scales the value column
narrow_sep=$(grep -m1 -E '^-+\+-+$' "$tmpdir/narrow.out")
narrow_right=${narrow_sep#*+}
if (( ${#narrow_right} != 30 )); then
  printf 'expected 30 dashes after + for --width=40, got %d\n' "${#narrow_right}" >&2
  exit 1
fi

# Same canonical Manufacturer line must still appear in both
validator_assert_contains "$tmpdir/wide.out" 'Manufacturer        |Canon'
validator_assert_contains "$tmpdir/narrow.out" 'Manufacturer        |Canon'
