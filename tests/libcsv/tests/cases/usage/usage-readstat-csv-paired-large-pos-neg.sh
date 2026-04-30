#!/usr/bin/env bash
# @testcase: usage-readstat-csv-paired-large-pos-neg
# @title: readstat CSV preserves paired very large positive and negative integers
# @description: Builds a CSV whose single numeric column alternates between very large positive and very large negative integers (up to 1e15 in magnitude), converts through DTA, and verifies each paired value reappears with its sign and magnitude intact and that no positive value collapses into its negative twin.
# @timeout: 180
# @tags: usage, csv, numeric, sign
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,value
pos_1e9,1000000000
neg_1e9,-1000000000
pos_1e12,1000000000000
neg_1e12,-1000000000000
pos_1e15,1000000000000000
neg_1e15,-1000000000000000
pos_5e14,500000000000000
neg_5e14,-500000000000000
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"value","label":"Value"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"pos_1e9",1000000000.000000'
validator_assert_contains "$tmpdir/out.csv" '"neg_1e9",-1000000000.000000'
validator_assert_contains "$tmpdir/out.csv" '"pos_1e12",1000000000000.000000'
validator_assert_contains "$tmpdir/out.csv" '"neg_1e12",-1000000000000.000000'
validator_assert_contains "$tmpdir/out.csv" '"pos_1e15",1000000000000000.000000'
validator_assert_contains "$tmpdir/out.csv" '"neg_1e15",-1000000000000000.000000'
validator_assert_contains "$tmpdir/out.csv" '"pos_5e14",500000000000000.000000'
validator_assert_contains "$tmpdir/out.csv" '"neg_5e14",-500000000000000.000000'

# Cross-check pairings: each positive entry must be exactly the negation of
# its paired counterpart, with no sign flips on readback.
python3 - "$tmpdir/out.csv" <<'PY'
import csv, sys
with open(sys.argv[1], newline="") as f:
    rows = list(csv.reader(f))
data = {r[0]: float(r[1]) for r in rows[1:] if r}
pairs = [
    ("pos_1e9", "neg_1e9"),
    ("pos_1e12", "neg_1e12"),
    ("pos_1e15", "neg_1e15"),
    ("pos_5e14", "neg_5e14"),
]
for p, n in pairs:
    if p not in data or n not in data:
        sys.stderr.write(f"missing pair {p}/{n}\n")
        sys.exit(1)
    if data[p] <= 0:
        sys.stderr.write(f"{p} not positive: {data[p]}\n")
        sys.exit(1)
    if data[n] >= 0:
        sys.stderr.write(f"{n} not negative: {data[n]}\n")
        sys.exit(1)
    if data[p] != -data[n]:
        sys.stderr.write(f"pair {p}/{n} not negations: {data[p]} vs {data[n]}\n")
        sys.exit(1)
PY

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 8'
