#!/usr/bin/env bash
# @testcase: usage-readstat-conversion-log-counts
# @title: readstat conversion log reports variable and row counts
# @description: Captures the stdout of three sequential conversions of a seven-row two-column CSV through DTA and SAV and CSV and verifies every conversion emits a "Converted N variables and M rows in T seconds" log line whose variable and row counts match the expected shape, locking in the structured success indicator.
# @timeout: 180
# @tags: usage, csv, log, counts
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,1
beta,2
gamma,3
delta,4
epsilon,5
zeta,6
eta,7
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

# CSV -> DTA.
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta" >"$tmpdir/log1" 2>&1
# DTA -> SAV.
readstat "$tmpdir/out.dta" "$tmpdir/out.sav" >"$tmpdir/log2" 2>&1
# DTA -> CSV.
readstat "$tmpdir/out.dta" "$tmpdir/back.csv" >"$tmpdir/log3" 2>&1

pat='^Converted 2 variables and 7 rows in [0-9]+\.[0-9]+ seconds$'
for log in "$tmpdir/log1" "$tmpdir/log2" "$tmpdir/log3"; do
  if ! grep -E "$pat" "$log" >/dev/null; then
    printf 'log %s did not match expected pattern\n' "$log" >&2
    cat "$log" >&2
    exit 1
  fi
done
