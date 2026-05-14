#!/usr/bin/env bash
# @testcase: usage-readstat-r18-sav-roundtrip-header-preserved
# @title: readstat CSV-to-SAV-to-CSV roundtrip preserves the column header tokens
# @description: Converts a small CSV to SAV via SPSS metadata, then back to stdout CSV, and asserts the recovered first line contains both column tokens "p" and "q" — locking in column header preservation through the SAV writer/reader pair.
# @timeout: 60
# @tags: usage, csv, sav, header, roundtrip, r18
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
p,q
1,2
3,4
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"NUMERIC","name":"p","label":"P"},{"type":"NUMERIC","name":"q","label":"Q"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.sav"
readstat "$tmpdir/mid.sav" - >"$tmpdir/out.csv"

header=$(head -n 1 "$tmpdir/out.csv")
for tok in p q; do
    case "$header" in
        *"$tok"*) ;;
        *) printf 'header missing %s: %s\n' "$tok" "$header" >&2; exit 1 ;;
    esac
done
