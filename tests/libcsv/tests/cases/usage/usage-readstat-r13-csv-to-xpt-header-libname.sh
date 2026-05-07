#!/usr/bin/env bash
# @testcase: usage-readstat-r13-csv-to-xpt-header-libname
# @title: readstat-produced XPT carries the HEADER RECORD LIBV8 magic in the first 80 bytes
# @description: Builds an XPT from a CSV via DTA and asserts the first 80-byte record of the output contains the canonical "HEADER RECORD" preamble and the "LIBV8" library-version-8 token that marks a SAS XPORT v8 transport file as written by readstat on Ubuntu 24.04, locking in that the readstat XPT writer emits a structurally recognisable XPORT file rather than an arbitrarily-formed binary.
# @timeout: 60
# @tags: usage, csv, xpt, magic
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,name
1,alice
2,bob
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"STRING","name":"name","label":"Name"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.xpt"

# The first XPT record is exactly 80 bytes and starts with HEADER RECORD*****LIBRARY...
head -c 80 "$tmpdir/out.xpt" >"$tmpdir/first_record"
size=$(wc -c <"$tmpdir/first_record")
[[ "$size" == "80" ]] || {
  printf 'expected first XPT record to be 80 bytes, got %s\n' "$size" >&2
  exit 1
}
validator_assert_contains "$tmpdir/first_record" 'HEADER RECORD'
# Ubuntu 24.04 readstat writes XPT v8 records, marked by the LIBV8 token.
validator_assert_contains "$tmpdir/first_record" 'LIBV8'
