#!/usr/bin/env bash
# @testcase: usage-readstat-csv-long-column-names
# @title: readstat long column names through DTA and SAV
# @description: Converts a CSV with column names longer than 32 characters through DTA and SAV and verifies the long names are preserved verbatim in the readback header for each format.
# @timeout: 240
# @tags: usage, csv, headers
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

long_a="alpha_extended_column_name_well_past_thirty_two_chars"
long_b="beta_extended_column_name_well_past_thirty_two_chars"

# Both names are 53 characters, well above the historic 32-char SPSS limit.
{
  printf '%s,%s\n' "$long_a" "$long_b"
  printf 'one,1\n'
  printf 'two,2\n'
} >"$tmpdir/in.csv"

python3 - "$tmpdir" "$long_a" "$long_b" <<'PY'
import json, os, sys
out, a, b = sys.argv[1], sys.argv[2], sys.argv[3]
meta = {
    "type": "Stata",
    "variables": [
        {"type": "STRING", "name": a, "label": "A"},
        {"type": "NUMERIC", "name": b, "label": "B"},
    ],
}
with open(os.path.join(out, "meta.json"), "w") as f:
    json.dump(meta, f)
PY

# Sanity: confirm both names exceed 32 characters.
[[ ${#long_a} -gt 32 ]] || { printf 'long_a not long enough\n' >&2; exit 1; }
[[ ${#long_b} -gt 32 ]] || { printf 'long_b not long enough\n' >&2; exit 1; }

# CSV -> DTA, then check the header.
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/dta.csv"
validator_assert_contains "$tmpdir/dta.csv" "\"$long_a\",\"$long_b\""
validator_assert_contains "$tmpdir/dta.csv" '"one",1.000000'
validator_assert_contains "$tmpdir/dta.csv" '"two",2.000000'

# DTA -> SAV, then check the header again.
readstat "$tmpdir/out.dta" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" - >"$tmpdir/sav.csv"
validator_assert_contains "$tmpdir/sav.csv" "\"$long_a\",\"$long_b\""
validator_assert_contains "$tmpdir/sav.csv" '"one",1.000000'
validator_assert_contains "$tmpdir/sav.csv" '"two",2.000000'

readstat "$tmpdir/out.sav" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'
