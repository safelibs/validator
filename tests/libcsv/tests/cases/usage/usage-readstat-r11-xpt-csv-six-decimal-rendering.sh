#!/usr/bin/env bash
# @testcase: usage-readstat-r11-xpt-csv-six-decimal-rendering
# @title: readstat XPT to CSV renders integer-valued numerics with six trailing decimals
# @description: Round-trips three integer-valued ids (1, 2, 3) through XPT (built via DTA) and back to CSV and verifies the readstat CSV writer emits each integer with the six-trailing-decimal "1.000000" / "2.000000" / "3.000000" rendering rather than as bare integers, exercising the XPT-reader -> CSV-writer pipeline's numeric formatting on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, csv, xpt, decimal-rendering
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
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"STRING","name":"name","label":"Name"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/mid.dta"
readstat "$tmpdir/mid.dta" "$tmpdir/cross.xpt"
readstat "$tmpdir/cross.xpt" - >"$tmpdir/out.csv"

validator_assert_contains "$tmpdir/out.csv" '"id","name"'
for line in '1.000000,"alice"' '2.000000,"bob"' '3.000000,"carol"'; do
  validator_assert_contains "$tmpdir/out.csv" "$line"
done
# A bare-integer rendering (no trailing decimals) would mean a regression.
if grep -E '^[0-9]+,"' "$tmpdir/out.csv" >/dev/null; then
  printf 'XPT->CSV path emitted bare integers, expected six-decimal form\n' >&2
  cat "$tmpdir/out.csv" >&2
  exit 1
fi
