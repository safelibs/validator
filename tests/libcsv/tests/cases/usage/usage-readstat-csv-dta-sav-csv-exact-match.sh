#!/usr/bin/env bash
# @testcase: usage-readstat-csv-dta-sav-csv-exact-match
# @title: readstat CSV through DTA SAV and back to CSV produces identical readback
# @description: Round-trips a CSV through DTA, then through SAV, then back to CSV via the SAV file, and verifies that the final CSV content is byte-for-byte identical to a direct CSV-through-DTA-and-back-to-CSV readback, locking in that the SAV intermediate hop does not perturb the data.
# @timeout: 240
# @tags: usage, csv, multistep, equivalence
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,10
beta,20
gamma,30
delta,40
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

# Path A: CSV -> DTA -> CSV (the single-hop reference readback).
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/refA.dta"
readstat "$tmpdir/refA.dta" - >"$tmpdir/readback_A.csv"

# Path B: CSV -> DTA -> SAV -> CSV (the full multi-hop chain).
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/stepB.dta"
readstat "$tmpdir/stepB.dta" "$tmpdir/stepB.sav"
validator_require_file "$tmpdir/stepB.sav"
readstat "$tmpdir/stepB.sav" - >"$tmpdir/readback_B.csv"

# Both readbacks must contain the same header and the same data rows.
validator_assert_contains "$tmpdir/readback_A.csv" '"name","score"'
validator_assert_contains "$tmpdir/readback_B.csv" '"name","score"'
for row in '"alpha",10.000000' '"beta",20.000000' '"gamma",30.000000' '"delta",40.000000'; do
  validator_assert_contains "$tmpdir/readback_A.csv" "$row"
  validator_assert_contains "$tmpdir/readback_B.csv" "$row"
done

# Strong equivalence: the two readbacks must be byte-identical.
if ! diff -u "$tmpdir/readback_A.csv" "$tmpdir/readback_B.csv" >"$tmpdir/diff.txt"; then
  printf 'CSV->DTA->CSV and CSV->DTA->SAV->CSV readbacks differ\n' >&2
  cat "$tmpdir/diff.txt" >&2
  exit 1
fi

# Both readbacks: header + 4 data rows = 5 lines.
for f in "$tmpdir/readback_A.csv" "$tmpdir/readback_B.csv"; do
  total=$(wc -l <"$f")
  [[ "$total" == "5" ]] || {
    printf 'expected 5 lines in %s, got %s\n' "$f" "$total" >&2
    cat "$f" >&2
    exit 1
  }
done

# Each intermediate file must agree on shape.
for f in "$tmpdir/refA.dta" "$tmpdir/stepB.dta" "$tmpdir/stepB.sav"; do
  readstat "$f" >"$tmpdir/summary"
  validator_assert_contains "$tmpdir/summary" 'Columns: 2'
  validator_assert_contains "$tmpdir/summary" 'Rows: 4'
done
