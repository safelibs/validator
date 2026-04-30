#!/usr/bin/env bash
# @testcase: usage-netpbm-pamslice-column-png
# @title: netpbm pamslice column from PNG fixture
# @description: Converts the basn2c08 fixture to PAM via pngtopam and uses pamslice -column 0 to extract the first column of pixel values; asserts pamslice produced 32 rows of tabular output.
# @timeout: 120
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pamslice-column-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopam "$png" >"$tmpdir/in.pam"
pamfile "$tmpdir/in.pam" | tee "$tmpdir/pamfile.txt"
validator_assert_contains "$tmpdir/pamfile.txt" '32 by 32'

pamslice -column 0 "$tmpdir/in.pam" >"$tmpdir/col0.txt"

# pamslice prints one row per pixel in the column, with the row index as the
# leading field followed by per-plane sample values. For a 32-row PPM this
# yields 32 lines whose first column counts 0..31.
nlines=$(wc -l <"$tmpdir/col0.txt")
if [[ "$nlines" -ne 32 ]]; then
  printf 'expected 32 lines from pamslice, got %s\n' "$nlines" >&2
  sed -n '1,40p' "$tmpdir/col0.txt" >&2
  exit 1
fi

# First field on first line must be 0; first field on last line must be 31.
first_idx=$(awk 'NR==1{print $1; exit}' "$tmpdir/col0.txt")
last_idx=$(awk 'END{print $1}' "$tmpdir/col0.txt")
if [[ "$first_idx" != "0" || "$last_idx" != "31" ]]; then
  printf 'unexpected row indices: first=%s last=%s\n' "$first_idx" "$last_idx" >&2
  exit 1
fi

# Each row of a PPM slice carries 3 sample values (R G B) plus the index = 4 fields.
nfields=$(awk 'NR==1{print NF; exit}' "$tmpdir/col0.txt")
if [[ "$nfields" -ne 4 ]]; then
  printf 'expected 4 fields per pamslice row (idx R G B), got %s\n' "$nfields" >&2
  exit 1
fi
