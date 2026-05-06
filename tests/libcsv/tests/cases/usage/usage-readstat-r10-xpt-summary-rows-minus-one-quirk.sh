#!/usr/bin/env bash
# @testcase: usage-readstat-r10-xpt-summary-rows-minus-one-quirk
# @title: readstat XPT summary reports Rows -1 and omits byte-order encoding compression lines
# @description: Builds a SAS XPORT file from a five-row CSV via DTA and verifies the readstat metadata summary reports the documented "Rows: -1" placeholder (XPORT does not store the row count in its header) and that the summary intentionally omits the Byte order, Text encoding, and Compression lines that DTA, SAV, and ZSAV emit, locking in the XPT-specific metadata shape.
# @timeout: 120
# @tags: usage, csv, xpt, summary
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,1
beta,2
gamma,3
delta,4
epsilon,5
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/out.xpt"
readstat "$tmpdir/out.xpt" >"$tmpdir/summary"

# XPT explicitly reports -1 for the unknown row count.
if ! grep -E '^Rows: -1$' "$tmpdir/summary" >/dev/null; then
  printf 'expected XPT summary to report "Rows: -1"\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
fi

# XPT summary must include the format identifier and column count.
validator_assert_contains "$tmpdir/summary" 'SAS transport file (XPORT)'
validator_assert_contains "$tmpdir/summary" 'Columns: 2'

# The XPT summary does NOT carry these fields; their absence is part of the
# format-specific shape we want to lock in.
for absent in '^Byte order: ' '^Text encoding: ' '^Compression: '; do
  if grep -E "$absent" "$tmpdir/summary" >/dev/null; then
    printf 'XPT summary unexpectedly contained line matching: %s\n' "$absent" >&2
    cat "$tmpdir/summary" >&2
    exit 1
  fi
done
