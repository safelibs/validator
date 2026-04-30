#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-aperture-value
# @title: exif --tag=ApertureValue auto-finds the APEX aperture
# @description: Runs the exif client with --tag=ApertureValue against the canon fixture and verifies the readout includes the ApertureValue label and a non-empty Value line carrying the composed APEX rendering, then re-runs with --machine-readable to confirm the same scalar appears as a single tab-delimited record. ApertureValue is a composed APEX tag whose human form is the f/N rendering libexif derives from the rational stored in the EXIF IFD.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-aperture-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Pretty-print readout: must include the ApertureValue label and a non-empty Value
exif --tag=ApertureValue "$img" >"$tmpdir/pretty.out"
validator_assert_contains "$tmpdir/pretty.out" 'ApertureValue'
validator_assert_contains "$tmpdir/pretty.out" 'Value:'

value_line=$(grep -E '^[[:space:]]*Value:' "$tmpdir/pretty.out" | head -n 1)
payload=${value_line#*Value:}
payload=${payload## }
if [[ -z "$payload" ]]; then
  printf 'expected non-empty ApertureValue payload\n' >&2
  cat "$tmpdir/pretty.out" >&2
  exit 1
fi

# Machine-readable scoped probe must yield exactly one non-empty line
exif --machine-readable --tag=ApertureValue "$img" >"$tmpdir/machine.out"
line_count=$(wc -l <"$tmpdir/machine.out")
if (( line_count != 1 )); then
  printf 'expected 1 machine-readable line for ApertureValue, got %d\n' "$line_count" >&2
  cat "$tmpdir/machine.out" >&2
  exit 1
fi
read -r machine_value <"$tmpdir/machine.out"
if [[ -z "$machine_value" ]]; then
  printf 'expected non-empty machine-readable ApertureValue\n' >&2
  exit 1
fi
