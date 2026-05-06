#!/usr/bin/env bash
# @testcase: usage-readstat-r10-csv-sav-text-encoding-utf8-default
# @title: readstat SAV summary reports Text encoding UTF-8 by default
# @description: Converts a CSV containing pure ASCII content directly into an SPSS SAV file using the SPSS metadata type and verifies the readstat summary reports the "Text encoding: UTF-8" line, locking in that newly created SAV files default to UTF-8 even when no Unicode characters are present in the source data.
# @timeout: 120
# @tags: usage, csv, sav, encoding
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
key,val
alpha,1
beta,2
gamma,3
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"SPSS","variables":[{"type":"STRING","name":"key","label":"K"},{"type":"NUMERIC","name":"val","label":"V"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.sav"
readstat "$tmpdir/out.sav" >"$tmpdir/summary"

# Text encoding line must be present and exactly UTF-8.
if ! grep -E '^Text encoding: UTF-8$' "$tmpdir/summary" >/dev/null; then
  printf 'expected "Text encoding: UTF-8" in SAV summary\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
fi

# Sanity: the file is still identified as the SPSS binary (SAV) format and
# carries the expected shape so we know the encoding line refers to this file.
validator_assert_contains "$tmpdir/summary" 'SPSS binary file (SAV)'
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 3'

# Exactly one Text encoding line per SAV summary.
count=$(grep -cE '^Text encoding: ' "$tmpdir/summary")
[[ "$count" == "1" ]] || {
  printf 'expected exactly one Text encoding line, got %s\n' "$count" >&2
  cat "$tmpdir/summary" >&2
  exit 1
}
