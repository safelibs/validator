#!/usr/bin/env bash
# @testcase: usage-readstat-summary-timestamp-line-shape
# @title: readstat summary timestamp line matches expected calendar shape
# @description: Generates a DTA and a SAV from a CSV and verifies each summary's "Timestamp:" line matches the day-month-year hour:minute pattern (DD MMM YYYY HH:MM) emitted by readstat, locking in that the calendar field is well-formed even though the actual moment depends on the test run time.
# @timeout: 180
# @tags: usage, csv, summary, timestamp
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
name,score
alpha,1
beta,2
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"STRING","name":"name","label":"Name"},{"type":"NUMERIC","name":"score","label":"Score"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" "$tmpdir/out.sav"

# Timestamp pattern: "Timestamp: DD Mon YYYY HH:MM" with three-letter month.
pat='^Timestamp: [0-9]{1,2} (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{4} [0-9]{2}:[0-9]{2}$'

for f in "$tmpdir/out.dta" "$tmpdir/out.sav"; do
  readstat "$f" >"$tmpdir/summary"
  if ! grep -E "$pat" "$tmpdir/summary" >/dev/null; then
    printf 'timestamp line did not match expected shape in %s\n' "$f" >&2
    cat "$tmpdir/summary" >&2
    exit 1
  fi
  # Exactly one timestamp line per summary.
  count=$(grep -cE '^Timestamp: ' "$tmpdir/summary")
  if [[ "$count" != "1" ]]; then
    printf 'expected exactly one Timestamp line in %s, got %s\n' "$f" "$count" >&2
    exit 1
  fi
done
