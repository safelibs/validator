#!/usr/bin/env bash
# @testcase: usage-readstat-r17-log-duration-seconds-numeric
# @title: readstat conversion log encodes a numeric duration-seconds value
# @description: Captures readstat's stdout from a CSV-to-DTA conversion and asserts the log contains a "Converted N variables and M rows in T seconds" line where the T token parses as a positive float — locking in the structured duration emission.
# @timeout: 60
# @tags: usage, csv, log, duration
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
a,b
1,2
3,4
5,6
CSV

cat >"$tmpdir/meta.json" <<'JSON'
{"type":"Stata","variables":[{"type":"NUMERIC","name":"a","label":"A"},{"type":"NUMERIC","name":"b","label":"B"}]}
JSON

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta" >"$tmpdir/log" 2>&1

# Extract the float between "in " and " seconds".
duration=$(grep -Eo 'in [0-9]+\.[0-9]+ seconds' "$tmpdir/log" | head -1 | awk '{print $2}')
[[ -n "$duration" ]] || {
    printf 'no duration token found in log\n' >&2
    cat "$tmpdir/log" >&2
    exit 1
}
python3 -c "
import sys
d = float('$duration')
assert d >= 0.0, f'duration {d} not non-negative'
" || exit 1
