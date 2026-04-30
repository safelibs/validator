#!/usr/bin/env bash
# @testcase: usage-readstat-dta-to-csv-with-meta-inspection
# @title: readstat DTA to CSV with metadata file inspection
# @description: Converts a CSV through DTA, then independently dumps the DTA back to CSV and the DTA metadata summary to a separate file, and verifies both that the data file readback carries the input rows and that the metadata file inspection reports the matching row, column, format header, and byte order alongside it.
# @timeout: 180
# @tags: usage, csv, metadata, inspection
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score,note
alpha,1,first
beta,2,second
gamma,3,third
delta,4,fourth
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"},{"type":"STRING","name":"note","label":"Note"}]}
JSON

# Build the DTA, then capture data and metadata into separate files.
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/data.csv"
readstat "$tmpdir/out.dta" >"$tmpdir/meta.txt"

# Data side: header plus every input row reappears.
validator_assert_contains "$tmpdir/data.csv" '"name","score","note"'
validator_assert_contains "$tmpdir/data.csv" '"alpha",1.000000,"first"'
validator_assert_contains "$tmpdir/data.csv" '"beta",2.000000,"second"'
validator_assert_contains "$tmpdir/data.csv" '"gamma",3.000000,"third"'
validator_assert_contains "$tmpdir/data.csv" '"delta",4.000000,"fourth"'

# Metadata side: inspecting the same DTA prints the matching shape and format.
validator_assert_contains "$tmpdir/meta.txt" 'Format: Stata binary file (DTA)'
validator_assert_contains "$tmpdir/meta.txt" 'Columns: 3'
validator_assert_contains "$tmpdir/meta.txt" 'Rows: 4'
validator_assert_contains "$tmpdir/meta.txt" 'Byte order: little-endian'

# Sanity: the metadata file must not be the CSV dump (no quoted-CSV rows).
if grep -E '^"[a-z]+",[0-9]+\.[0-9]+' "$tmpdir/meta.txt" >/dev/null; then
  printf 'metadata file unexpectedly contains CSV data rows\n' >&2
  cat "$tmpdir/meta.txt" >&2
  exit 1
fi

# And the data CSV must not contain the metadata "Format:" header line.
if grep -E '^Format:' "$tmpdir/data.csv" >/dev/null; then
  printf 'data CSV unexpectedly contains metadata header line\n' >&2
  cat "$tmpdir/data.csv" >&2
  exit 1
fi

# Total rows in the data CSV: header + 4 data rows.
total=$(wc -l <"$tmpdir/data.csv")
[[ "$total" == "5" ]] || {
  printf 'expected 5 lines in data.csv, got %s\n' "$total" >&2
  exit 1
}
