#!/usr/bin/env bash
# @testcase: usage-readstat-csv-many-columns-roundtrip
# @title: readstat 30 column CSV round trip
# @description: Builds a 30-column numeric CSV with matching metadata, converts through DTA, and verifies the column count and first and last column values survive.
# @timeout: 180
# @tags: usage, csv, columns
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import json, os, sys
out = sys.argv[1]
n = 30
header = ",".join(f"c{i}" for i in range(n))
row1 = ",".join(str(i) for i in range(n))
row2 = ",".join(str(i * 7) for i in range(n))
with open(os.path.join(out, "in.csv"), "w") as f:
    f.write(header + "\n" + row1 + "\n" + row2 + "\n")
meta = {
    "type": "Stata",
    "variables": [
        {"type": "NUMERIC", "name": f"c{i}", "label": f"Col{i}"}
        for i in range(n)
    ],
}
with open(os.path.join(out, "meta.json"), "w") as f:
    json.dump(meta, f)
PY

readstat "$tmpdir/in.csv" "$tmpdir/meta.json" "$tmpdir/out.dta"

readstat "$tmpdir/out.dta" >"$tmpdir/summary"
validator_assert_contains "$tmpdir/summary" 'Columns: 30'
validator_assert_contains "$tmpdir/summary" 'Rows: 2'

readstat "$tmpdir/out.dta" - >"$tmpdir/out.csv"

# Header must include first and last column names.
header_line=$(head -n 1 "$tmpdir/out.csv")
[[ "$header_line" == *'"c0"'* ]] || { printf 'missing c0 in header: %s\n' "$header_line" >&2; exit 1; }
[[ "$header_line" == *'"c29"'* ]] || { printf 'missing c29 in header: %s\n' "$header_line" >&2; exit 1; }

# Row 1: c0=0, c29=29. Row 2: c0=0, c29=203 (29*7).
row1=$(sed -n '2p' "$tmpdir/out.csv")
row2=$(sed -n '3p' "$tmpdir/out.csv")
[[ "$row1" == 0.000000* ]] || { printf 'row1 leading value wrong: %s\n' "$row1" >&2; exit 1; }
[[ "$row1" == *,29.000000 ]] || { printf 'row1 trailing value wrong: %s\n' "$row1" >&2; exit 1; }
[[ "$row2" == *,203.000000 ]] || { printf 'row2 trailing value wrong: %s\n' "$row2" >&2; exit 1; }

# Total of 3 lines: header + 2 data rows.
total=$(wc -l <"$tmpdir/out.csv")
[[ "$total" == "3" ]] || { printf 'expected 3 lines, got %s\n' "$total" >&2; cat "$tmpdir/out.csv" >&2; exit 1; }
