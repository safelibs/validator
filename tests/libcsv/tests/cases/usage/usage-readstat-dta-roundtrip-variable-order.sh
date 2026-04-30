#!/usr/bin/env bash
# @testcase: usage-readstat-dta-roundtrip-variable-order
# @title: readstat DTA to DTA preserves variable order
# @description: Converts a CSV with a deliberately non-alphabetical column order (zulu, alpha, mike) into DTA, then re-encodes that DTA into a second DTA file, and verifies the readback header on both DTAs lists the columns in the original input order rather than reordered.
# @timeout: 180
# @tags: usage, csv, ordering
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
zulu,alpha,mike
26,1,13
260,10,130
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"zulu","label":"Zulu"},{"type":"NUMERIC","name":"alpha","label":"Alpha"},{"type":"NUMERIC","name":"mike","label":"Mike"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/first.dta"
readstat "$tmpdir/first.dta" "$tmpdir/second.dta"
validator_require_file "$tmpdir/second.dta"

readstat "$tmpdir/first.dta" - >"$tmpdir/first.csv"
readstat "$tmpdir/second.dta" - >"$tmpdir/second.csv"

expected_header='"zulu","alpha","mike"'
for csv in "$tmpdir/first.csv" "$tmpdir/second.csv"; do
  got=$(head -n 1 "$csv")
  [[ "$got" == "$expected_header" ]] || {
    printf 'expected header %s in %s, got %s\n' "$expected_header" "$csv" "$got" >&2
    exit 1
  }
done

# Row 1 values: zulu=26, alpha=1, mike=13. Order matters.
expected_row1='26.000000,1.000000,13.000000'
got_row1=$(sed -n '2p' "$tmpdir/second.csv")
[[ "$got_row1" == "$expected_row1" ]] || {
  printf 'second DTA row1 mismatch: %s\n' "$got_row1" >&2
  exit 1
}

# Row 2 values: zulu=260, alpha=10, mike=130.
expected_row2='260.000000,10.000000,130.000000'
got_row2=$(sed -n '3p' "$tmpdir/second.csv")
[[ "$got_row2" == "$expected_row2" ]] || {
  printf 'second DTA row2 mismatch: %s\n' "$got_row2" >&2
  exit 1
}

readstat "$tmpdir/second.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 3'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'
