#!/usr/bin/env bash
# @testcase: usage-readstat-r16-dta-roundtrip-1000-rows-shape
# @title: readstat round-trips a 1000-row CSV through DTA preserving row count
# @description: Generates a 1000-row two-column numeric CSV and asserts that the readstat DTA round-trip back to CSV recovers 1001 lines (header + 1000 data) and that both the summary "Rows: 1000" line and a representative interior data row survive the round trip.
# @timeout: 180
# @tags: usage, csv, dta, scale
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

{
    printf 'id,sq\n'
    python3 -c "
for i in range(1, 1001):
    print(f'{i},{i*i}')
"
} >"$tmpdir/in.csv"

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"id","label":"ID"},{"type":"NUMERIC","name":"sq","label":"SQ"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Rows: 1000'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"
lc=$(wc -l <"$tmpdir/out.csv")
[[ "$lc" -eq 1001 ]] || {
    printf 'expected 1001 lines got %s\n' "$lc" >&2
    exit 1
}
# Interior row 500 -> 500*500 = 250000
grep -E '(^|,)500(,|$)' "$tmpdir/out.csv" >/dev/null
grep -E '(^|,)250000(,|$)' "$tmpdir/out.csv" >/dev/null
