#!/usr/bin/env bash
# @testcase: usage-readstat-r11-xpt-csv-row-count-correct-after-conversion
# @title: readstat XPT to CSV emits all rows even though the XPT header reports Rows -1
# @description: Builds an XPT from a five-row CSV via DTA and verifies that, despite the XPT summary reporting the documented "Rows: -1" placeholder, the readstat XPT-to-CSV conversion still emits a header line and all five data rows, locking in the asymmetry between XPT metadata row reporting and actual row enumeration during conversion.
# @timeout: 60
# @tags: usage, csv, xpt, row-count
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,name
1,alice
2,bob
3,carol
4,dave
5,eve
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"STRING","name":"name","label":"Name"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/cross.xpt"
readstat "$tmpdir/cross.xpt" >"$tmpdir/summary"
readstat "$tmpdir/cross.xpt" - >"$tmpdir/data.csv"

# Summary says rows: -1 (XPT placeholder).
grep -E '^Rows: -1$' "$tmpdir/summary" >/dev/null || {
  printf 'XPT summary did not report Rows: -1 placeholder\n' >&2
  cat "$tmpdir/summary" >&2
  exit 1
}

# Conversion still emits header plus five rows = six total lines.
line_count=$(wc -l <"$tmpdir/data.csv")
[[ "$line_count" -eq 6 ]] || {
  printf 'XPT->CSV produced %s lines, expected 6 (header + 5 rows)\n' "$line_count" >&2
  cat "$tmpdir/data.csv" >&2
  exit 1
}

# Every input value reappears in the conversion.
for name in alice bob carol dave eve; do
  validator_assert_contains "$tmpdir/data.csv" "\"$name\""
done
