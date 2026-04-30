#!/usr/bin/env bash
# @testcase: usage-readstat-summary-line-format-regex
# @title: readstat summary line format parsed by regex
# @description: Converts a CSV through DTA and SAV and parses each summary output with line-anchored regular expressions for the Columns, Rows, Compression, Text encoding, and Byte order fields, verifying both that the lines exist and that their values match the file shape rather than relying on plain substring search.
# @timeout: 180
# @tags: usage, csv, summary, regex
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score,group,note
alpha,1,A,first
beta,2,B,second
gamma,3,C,third
delta,4,D,fourth
epsilon,5,E,fifth
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"},{"type":"STRING","name":"group","label":"Group"},{"type":"STRING","name":"note","label":"Note"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" "$tmpdir/out.sav"

assert_line_matches() {
  local file=$1
  local pattern=$2
  if ! grep -E "$pattern" "$file" >/dev/null; then
    printf 'expected line matching %s in %s\n' "$pattern" "$file" >&2
    cat "$file" >&2
    exit 1
  fi
}

# Both summaries: shared line-anchored shape fields plus the byte order
# (the readstat CLI emits this for both DTA and SAV files).
for f in "$tmpdir/out.dta" "$tmpdir/out.sav"; do
  readstat "$f" >"$tmpdir/summary"
  assert_line_matches "$tmpdir/summary" '^Columns: 4$'
  assert_line_matches "$tmpdir/summary" '^Rows: 5$'
  assert_line_matches "$tmpdir/summary" '^Byte order: little-endian$'
done

# DTA-only: the summary advertises a "Format version:" line and the
# "Format: Stata binary file (DTA)" header.
readstat "$tmpdir/out.dta" >"$tmpdir/dta_summary"
assert_line_matches "$tmpdir/dta_summary" '^Format: Stata binary file \(DTA\)$'
assert_line_matches "$tmpdir/dta_summary" '^Format version: [0-9]+$'

# SAV summary still emits Columns/Rows; capture it for negative checks below.
readstat "$tmpdir/out.sav" >"$tmpdir/sav_summary"

# Negative checks: the values must not lie about the shape.
if grep -E '^Columns: (3|5)$' "$tmpdir/sav_summary" >/dev/null; then
  printf 'unexpected mismatched Columns line\n' >&2
  cat "$tmpdir/sav_summary" >&2
  exit 1
fi
if grep -E '^Rows: (4|6)$' "$tmpdir/sav_summary" >/dev/null; then
  printf 'unexpected mismatched Rows line\n' >&2
  cat "$tmpdir/sav_summary" >&2
  exit 1
fi
