#!/usr/bin/env bash
# @testcase: usage-readstat-r10-csv-header-only-no-data-rejected
# @title: readstat rejects a CSV that has only a header row
# @description: Provides a CSV consisting solely of a header line with no data rows and verifies readstat fails the conversion with a "One or more columns must be provided" diagnostic on stderr while leaving no output file behind, distinguishing the empty-data-row case from the empty-file case which has its own dedicated diagnostic.
# @timeout: 60
# @tags: usage, csv, parsing, negative
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Header line only, no data rows.
printf 'name,score\n' >"$tmpdir/in.csv"

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta" \
  >"$tmpdir/stdout" 2>"$tmpdir/stderr" || true
cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"

# Diagnostic must be present.
validator_assert_contains "$tmpdir/all" 'One or more columns must be provided'

# The "Converted 0 variables and 0 rows" log line confirms readstat noticed the
# zero-data-row condition rather than silently emitting an empty .dta.
validator_assert_contains "$tmpdir/all" 'Converted 0 variables and 0 rows'

# No output file must be created.
if [[ -e "$tmpdir/out.dta" ]]; then
  printf 'unexpected output file created\n' >&2
  ls -la "$tmpdir/out.dta" >&2
  exit 1
fi
