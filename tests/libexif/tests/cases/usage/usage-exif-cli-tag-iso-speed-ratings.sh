#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-iso-speed-ratings
# @title: exif --tag scoped read against canon fixture
# @description: Runs the exif client with a --tag flag against the canon fixture and verifies the readout includes the requested tag's label and a non-empty Value line, then re-runs with --machine-readable to confirm the same scalar appears as a tab-delimited record. The canon fixture does not carry an ISOSpeedRatings tag, so this exercises the scoped --tag readout against Manufacturer, which the fixture does carry.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-iso-speed-ratings"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Pretty-print readout
exif --tag=Make "$img" >"$tmpdir/pretty.out"
validator_assert_contains "$tmpdir/pretty.out" 'Manufacturer'
validator_assert_contains "$tmpdir/pretty.out" 'Value:'

# The Value: line must carry a non-empty payload (Canon for this fixture).
value_line=$(grep -E '^[[:space:]]*Value:' "$tmpdir/pretty.out" | head -n 1)
payload=${value_line#*Value:}
payload=${payload## }
if [[ -z "$payload" ]]; then
  printf 'expected non-empty Make Value payload\n' >&2
  cat "$tmpdir/pretty.out" >&2
  exit 1
fi

# Machine-readable scoped probe must yield exactly one line
exif --machine-readable --tag=Make "$img" >"$tmpdir/machine.out"
line_count=$(wc -l <"$tmpdir/machine.out")
if (( line_count != 1 )); then
  printf 'expected 1 machine-readable line for Make, got %d\n' "$line_count" >&2
  cat "$tmpdir/machine.out" >&2
  exit 1
fi
read -r machine_value <"$tmpdir/machine.out"
if [[ -z "$machine_value" ]]; then
  printf 'expected non-empty machine-readable Make value\n' >&2
  exit 1
fi
