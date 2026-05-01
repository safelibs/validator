#!/usr/bin/env bash
# @testcase: usage-readstat-csv-variable-labels-embedded-in-dta
# @title: readstat preserves multi-word variable labels in DTA
# @description: Drives readstat with a JSON metadata file declaring three columns whose labels are multi-word strings ("First Name", "Family Surname", "Age in Years"), converts the CSV to DTA, and verifies all three label strings are present in the binary DTA payload by scanning with strings(1). Variable labels are part of the libreadstat contract that calling code (Stata, pandas) relies on for column documentation.
# @timeout: 120
# @tags: usage, csv, dta, labels, metadata
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
firstname,lastname,age
alpha,one,21
beta,two,22
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"firstname","label":"First Name"},{"type":"STRING","name":"lastname","label":"Family Surname"},{"type":"NUMERIC","name":"age","label":"Age in Years"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
validator_require_file "$tmpdir/out.dta"

# strings(1) extracts ASCII runs from the binary; all three labels must appear.
strings "$tmpdir/out.dta" >"$tmpdir/strings"
for label in 'First Name' 'Family Surname' 'Age in Years'; do
  if ! grep -F -- "$label" "$tmpdir/strings" >/dev/null; then
    printf 'label missing from DTA payload: %s\n' "$label" >&2
    exit 1
  fi
done

# Sanity: data still readable back through readstat.
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
validator_assert_contains "$tmpdir/out.csv" '"firstname","lastname","age"'
validator_assert_contains "$tmpdir/out.csv" '"alpha","one",21.000000'
validator_assert_contains "$tmpdir/out.csv" '"beta","two",22.000000'
