#!/usr/bin/env bash
# @testcase: usage-readstat-r21-csv-sav-distinct-floats-survive
# @title: readstat CSV-SAV-CSV roundtrip preserves four distinct decimal values
# @description: Builds a four-row CSV with distinct decimal values (1.5, 2.5, 3.5, 4.5), converts through .sav and back to stdout CSV, and asserts each decimal token appears in the recovered output - locking in decimal preservation through the SAV writer path on a four-value sequence distinct from prior 3.5-only or integer tests.
# @timeout: 60
# @tags: usage, csv, sav, decimals, r21
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
v
1.5
2.5
3.5
4.5
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.sav"
readstat "$tmpdir/mid.sav" - >"$tmpdir/out.csv"

for v in 1.5 2.5 3.5 4.5; do
    validator_assert_contains "$tmpdir/out.csv" "$v"
done
