#!/usr/bin/env bash
# @testcase: usage-readstat-r18-negative-integer-rendering
# @title: readstat preserves negative integer cells in CSV-to-DTA-to-CSV roundtrips
# @description: Converts a CSV containing a column of negative integers through DTA and back to stdout CSV, then asserts each negative value appears in the recovered output with the six-decimal numeric rendering ("-1.000000", "-2.000000", "-3.000000").
# @timeout: 60
# @tags: usage, csv, dta, negative, r18
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
n
-1
-2
-3
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"n","label":"N"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

for val in '-1.000000' '-2.000000' '-3.000000'; do
    validator_assert_contains "$tmpdir/out.csv" "$val"
done
