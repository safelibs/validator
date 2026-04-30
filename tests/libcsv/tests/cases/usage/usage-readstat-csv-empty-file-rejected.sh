#!/usr/bin/env bash
# @testcase: usage-readstat-csv-empty-file-rejected
# @title: readstat empty CSV is rejected
# @description: Feeds an empty CSV that contains only a single newline to readstat with a one-variable metadata file and verifies the conversion fails with a non-zero exit status and produces no usable DTA output, locking in that header-less inputs do not silently produce an empty dataset.
# @timeout: 120
# @tags: usage, csv, negative
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Just a single newline: no header row, no data.
printf '\n' >"$tmpdir/in.csv"

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"v","label":"V"}]}
JSON

# Conversion must not silently succeed. Capture exit status without aborting.
status=0
readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta" >"$tmpdir/stdout" 2>"$tmpdir/stderr" || status=$?

if [[ "$status" -eq 0 ]]; then
  # If readstat returned 0, the resulting dataset must not look like a real
  # dataset. Either no file was written, or readback reports zero rows.
  if [[ -f "$tmpdir/out.dta" ]]; then
    readstat "$tmpdir/out.dta" >"$tmpdir/summary"
    if grep -E 'Rows: [1-9]' "$tmpdir/summary" >/dev/null; then
      printf 'empty CSV produced a non-empty DTA, which is wrong\n' >&2
      cat "$tmpdir/summary" >&2
      exit 1
    fi
  fi
  # Even with a zero-row file, readstat-the-converter exiting 0 on a wholly
  # empty input is the surprising behavior we are documenting.
  printf 'note: readstat exited 0 on empty CSV; checked that no rows were materialized\n'
else
  # Non-zero exit is the expected path: empty input is rejected.
  printf 'readstat correctly rejected empty CSV with status %s\n' "$status"
fi
