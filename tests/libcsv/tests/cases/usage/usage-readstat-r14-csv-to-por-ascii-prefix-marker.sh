#!/usr/bin/env bash
# @testcase: usage-readstat-r14-csv-to-por-ascii-prefix-marker
# @title: readstat-produced POR carries the "ASCII SPSS PORT FILE" prefix in its leading region
# @description: Builds an SPSS POR from a CSV via DTA and asserts the first kilobyte of the output contains the literal "ASCII SPSS PORT FILE" prefix that the readstat POR writer emits, distinguishing the more specific ASCII-prefixed marker from the bare "SPSS PORT FILE" substring already covered.
# @timeout: 120
# @tags: usage, csv, por, magic
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
NAME,SCORE
alpha,1
beta,2
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"NAME","label":"Name"},{"type":"NUMERIC","name":"SCORE","label":"S"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.por"

head -c 1024 "$tmpdir/out.por" >"$tmpdir/head"
if ! grep -aFq 'ASCII SPSS PORT FILE' "$tmpdir/head"; then
  printf 'POR header missing "ASCII SPSS PORT FILE" prefix in first KiB:\n' >&2
  od -An -c "$tmpdir/head" | head -10 >&2
  exit 1
fi
