#!/usr/bin/env bash
# @testcase: usage-python3-csv-roundtrip
# @title: python csv round trip
# @description: Exercises python csv round trip through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-csv-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/out.csv"
import csv
import sys
path = sys.argv[1]
with open(path, 'w', newline='', encoding='ascii') as handle:
    writer = csv.writer(handle)
    writer.writerow(['name', 'value'])
    writer.writerow(['alpha', '7'])
with open(path, newline='', encoding='ascii') as handle:
    rows = list(csv.reader(handle))
assert rows == [['name', 'value'], ['alpha', '7']]
print(rows[1][0], rows[1][1])
PY
