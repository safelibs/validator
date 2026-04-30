#!/usr/bin/env bash
# @testcase: usage-readstat-csv-all-zero-column-rendering
# @title: readstat all-zero numeric column renders as 0.000000 in every cell
# @description: Builds a CSV with two numeric columns where the first column carries varied non-zero integers and the second column is all zero across four rows, converts through DTA, and verifies the second column is rendered as the literal six-decimal short form 0.000000 in every row — never as a bare 0, never as 0.0, never as scientific notation, and never empty — while the first column independently renders its varied values.
# @timeout: 180
# @tags: usage, csv, numeric, zero, rendering
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
seq,zero
10,0
20,0
30,0
40,0
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"seq","label":"Seq"},{"type":"NUMERIC","name":"zero","label":"Zero"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Header.
header=$(sed -n '1p' "$tmpdir/out.csv")
[[ "$header" == '"seq","zero"' ]] || {
  printf 'unexpected header: %s\n' "$header" >&2
  exit 1
}

# Each data row's second field must be exactly the literal "0.000000".
for ln in 2 3 4 5; do
  field2=$(sed -n "${ln}p" "$tmpdir/out.csv" | cut -d, -f2)
  [[ "$field2" == "0.000000" ]] || {
    printf 'line %s column 2 expected 0.000000, got %s\n' "$ln" "$field2" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
  }
done

# First column renders its varied integer values in six-decimal short form.
for v in 10 20 30 40; do
  validator_assert_contains "$tmpdir/out.csv" "$v.000000,0.000000"
done

# Disallowed zero renderings.
forbidden_re='(,0$|,0\.0,|,0\.0$|,0e|,0\.0e|,0\.000000000|,$)'
if grep -E "$forbidden_re" "$tmpdir/out.csv" >/dev/null; then
  printf 'unexpected zero rendering form\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi

# Exactly four 0.000000 cells in the file (one per data row, all in column 2).
zero_count=$(grep -cE ',0\.000000$' "$tmpdir/out.csv")
[[ "$zero_count" == "4" ]] || {
  printf 'expected 4 zero-suffixed rows, got %s\n' "$zero_count" >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
}

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 4'
