#!/usr/bin/env bash
# @testcase: usage-readstat-csv-very-long-field
# @title: readstat CSV with a 1500 character single field
# @description: Builds a CSV whose string column carries a single field longer than 1500 characters, declares its width via metadata, converts through DTA, and verifies the full string reappears verbatim on readback alongside its sibling short-field row.
# @timeout: 180
# @tags: usage, csv, long-field
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import json, os, sys
out = sys.argv[1]
# 1500-character payload; uses a repeating pattern so it is easy to verify.
long_field = ("x" * 100 + "y" * 100 + "z" * 100) * 5  # 1500 chars
assert len(long_field) == 1500
with open(os.path.join(out, "in.csv"), "w") as f:
    f.write("name,note\n")
    f.write(f"long,{long_field}\n")
    f.write("short,tiny\n")
with open(os.path.join(out, "long_expected"), "w") as f:
    f.write(long_field)
# DTA strings need a width; pick one comfortably above 1500.
meta = {
    "type": "Stata",
    "variables": [
        {"type": "STRING", "name": "name", "label": "Name"},
        {"type": "STRING", "name": "note", "label": "Note", "length": 2000},
    ],
}
with open(os.path.join(out, "meta.json"), "w") as f:
    json.dump(meta, f)
PY

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"
readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Confirm both rows survive.
validator_assert_contains "$tmpdir/out.csv" '"name","note"'
validator_assert_contains "$tmpdir/out.csv" '"short","tiny"'

# The long field must round-trip verbatim. Extract the long row's note column
# and compare it against the saved expected payload.
python3 - "$tmpdir/out.csv" "$tmpdir/long_expected" <<'PY'
import csv, sys
out_csv = sys.argv[1]
expected_path = sys.argv[2]
with open(expected_path) as f:
    expected = f.read()
with open(out_csv, newline="") as f:
    rows = list(csv.reader(f))
header = rows[0]
assert header == ["name", "note"], f"unexpected header: {header}"
long_rows = [r for r in rows[1:] if r and r[0] == "long"]
assert len(long_rows) == 1, f"expected 1 long row, found {len(long_rows)}"
got = long_rows[0][1]
if got != expected:
    sys.stderr.write(f"long field mismatch: len(expected)={len(expected)} len(got)={len(got)}\n")
    sys.exit(1)
PY

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 2'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'
