#!/usr/bin/env bash
# @testcase: usage-readstat-csv-3col-10row-simple-roundtrip
# @title: readstat 3 column 10 row CSV roundtrip
# @description: Converts a CSV with three numeric columns and ten data rows through DTA and verifies the summary reports the exact row and column counts and that each row reappears with the expected six-decimal values.
# @timeout: 180
# @tags: usage, csv, roundtrip
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import os, sys
out = sys.argv[1]
with open(os.path.join(out, "in.csv"), "w") as f:
    f.write("a,b,c\n")
    for i in range(1, 11):
        f.write(f"{i},{i*2},{i*3}\n")
PY

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"a","label":"A"},{"type":"NUMERIC","name":"b","label":"B"},{"type":"NUMERIC","name":"c","label":"C"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 3'
validator_assert_contains "$tmpdir/summary" 'Rows: 10'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"a","b","c"'
for i in 1 2 3 4 5 6 7 8 9 10; do
  expected=$(printf '%d.000000,%d.000000,%d.000000' "$i" $((i*2)) $((i*3)))
  validator_assert_contains "$tmpdir/out.csv" "$expected"
done

# Header + 10 rows.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "11" ]] || {
  printf 'expected 11 lines, got %s\n' "$total" >&2
  exit 1
}
