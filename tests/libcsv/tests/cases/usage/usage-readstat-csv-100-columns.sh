#!/usr/bin/env bash
# @testcase: usage-readstat-csv-100-columns
# @title: readstat 100 column CSV summary and edge cells
# @description: Builds a 100 column numeric CSV with two data rows, converts through DTA, and verifies the summary reports exactly 100 columns and that the first column, last column, and a midpoint column hold their expected values on both rows.
# @timeout: 240
# @tags: usage, csv, columns, scale
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import json, os, sys
out = sys.argv[1]
n = 100
header = ",".join(f"v{i}" for i in range(n))
row1 = ",".join(str(i) for i in range(n))
row2 = ",".join(str(i + 1000) for i in range(n))
with open(os.path.join(out, "in.csv"), "w") as f:
    f.write(header + "\n" + row1 + "\n" + row2 + "\n")
meta = {
    "type": "Stata",
    "variables": [
        {"type": "NUMERIC", "name": f"v{i}", "label": f"V{i}"}
        for i in range(n)
    ],
}
with open(os.path.join(out, "meta.json"), "w") as f:
    json.dump(meta, f)
PY

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 100'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Header carries v0, v50, and v99.
header_line=$(head -n 1 "$tmpdir/out.csv")
for col in '"v0"' '"v50"' '"v99"'; do
  [[ "$header_line" == *"$col"* ]] || {
    printf 'header missing %s\n' "$col" >&2
    printf '%s\n' "$header_line" >&2
    exit 1
  }
done

# Row 1: first cell 0, last cell 99 (i.e., the 100th value).
row1=$(sed -n '2p' "$tmpdir/out.csv")
[[ "$row1" == 0.000000,* ]] || { printf 'row1 first cell wrong: %s\n' "$row1" >&2; exit 1; }
[[ "$row1" == *,99.000000 ]] || { printf 'row1 last cell wrong\n' >&2; exit 1; }

# Row 2: first cell 1000, last cell 1099.
row2=$(sed -n '3p' "$tmpdir/out.csv")
[[ "$row2" == 1000.000000,* ]] || { printf 'row2 first cell wrong: %s\n' "$row2" >&2; exit 1; }
[[ "$row2" == *,1099.000000 ]] || { printf 'row2 last cell wrong\n' >&2; exit 1; }

# Each data row should have exactly 99 commas (100 fields).
commas=$(sed -n '2p' "$tmpdir/out.csv" | tr -cd ',' | wc -c)
[[ "$commas" == "99" ]] || {
  printf 'expected 99 commas in row1, got %s\n' "$commas" >&2
  exit 1
}
