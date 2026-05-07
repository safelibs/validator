#!/usr/bin/env bash
# @testcase: usage-readstat-r13-csv-to-por-file-magic-spss-port
# @title: readstat-produced POR contains the SPSS PORT FILE marker in its leading region
# @description: Builds an SPSS portable POR file from a CSV via DTA and asserts the first kilobyte of the output contains the literal "SPSS PORT FILE" marker that the SPSS portable header embeds, locking in that the readstat POR writer emits a structurally recognisable SPSS portable text file rather than a CSV-shaped placeholder.
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

# SPSS portable headers carry the "SPSS PORT FILE" marker in the leading region.
head -c 1024 "$tmpdir/out.por" >"$tmpdir/head"
if ! grep -aFq 'SPSS PORT FILE' "$tmpdir/head"; then
  printf 'POR header missing "SPSS PORT FILE" marker in first KiB:\n' >&2
  od -An -c "$tmpdir/head" | head -10 >&2
  exit 1
fi
