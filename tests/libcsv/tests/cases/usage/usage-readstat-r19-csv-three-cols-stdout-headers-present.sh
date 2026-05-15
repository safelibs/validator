#!/usr/bin/env bash
# @testcase: usage-readstat-r19-csv-three-cols-stdout-headers-present
# @title: readstat stdout CSV preserves all three header tokens through a DTA hop
# @description: Builds a CSV with three numeric columns named alpha, beta, gamma, converts to .dta, then back to stdout CSV and asserts the recovered first line contains all three header tokens - locking in three-column header preservation through the DTA reader and writer.
# @timeout: 60
# @tags: usage, csv, dta, header, three-columns, r19
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
alpha,beta,gamma
1,2,3
4,5,6
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"alpha","label":"A"},{"type":"NUMERIC","name":"beta","label":"B"},{"type":"NUMERIC","name":"gamma","label":"G"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" - >"$tmpdir/out.csv"

header=$(head -n 1 "$tmpdir/out.csv")
for tok in alpha beta gamma; do
    case "$header" in
        *"$tok"*) ;;
        *) printf 'header missing %s: %s\n' "$tok" "$header" >&2; exit 1 ;;
    esac
done
