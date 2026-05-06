#!/usr/bin/env bash
# @testcase: usage-readstat-r10-csv-leading-zero-string-preserved
# @title: readstat preserves leading-zero codes when the column is STRING
# @description: Round-trips a CSV column containing zero-padded numeric-looking codes (007, 042, 099) declared as STRING through DTA and back to CSV, verifying the leading zeros survive intact rather than being silently coerced to numeric values like 7, 42, 99.
# @timeout: 120
# @tags: usage, csv, string, leading-zero
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
code,quantity
007,5
042,17
099,3
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"code","label":"Code"},{"type":"NUMERIC","name":"quantity","label":"Qty"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Zero-padded values must reappear verbatim in the readback.
validator_assert_contains "$tmpdir/out.csv" '"007",5.000000'
validator_assert_contains "$tmpdir/out.csv" '"042",17.000000'
validator_assert_contains "$tmpdir/out.csv" '"099",3.000000'

# The bare unpadded numeric forms must NOT appear as the stringified codes.
for stripped in '"7"' '"42"' '"99"'; do
  if grep -F -- "$stripped" "$tmpdir/out.csv" >/dev/null; then
    printf 'leading zeros lost: %s present in readback\n' "$stripped" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
  fi
done
