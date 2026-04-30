#!/usr/bin/env bash
# @testcase: usage-python3-yaml-type-preservation-jq
# @title: PyYAML type preservation for ints floats dates and timestamps
# @description: Loads a YAML document with int, float, bool, date, and datetime scalars via CSafeLoader and verifies Python types and exact values, plus a jq sanity check on the JSON projection.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/types.yaml" <<'YAML'
plain_int: 42
neg_int: -7
plain_float: 3.5
sci_float: 1.5e+3
truth: true
falsy: false
nullable: null
the_date: 2024-05-17
the_datetime: 2024-05-17T08:30:00Z
YAML

python3 - "$tmpdir/types.yaml" "$tmpdir/types.json" <<'PY'
import datetime
import json
import sys
import yaml

src, dst = sys.argv[1], sys.argv[2]
with open(src, "r", encoding="utf-8") as fh:
    data = yaml.load(fh, Loader=yaml.CSafeLoader)

assert type(data["plain_int"]) is int and data["plain_int"] == 42
assert type(data["neg_int"]) is int and data["neg_int"] == -7
assert type(data["plain_float"]) is float and data["plain_float"] == 3.5
assert type(data["sci_float"]) is float and data["sci_float"] == 1500.0
assert data["truth"] is True
assert data["falsy"] is False
assert data["nullable"] is None
assert isinstance(data["the_date"], datetime.date) and not isinstance(data["the_date"], datetime.datetime)
assert data["the_date"] == datetime.date(2024, 5, 17)
assert isinstance(data["the_datetime"], datetime.datetime)
assert data["the_datetime"] == datetime.datetime(2024, 5, 17, 8, 30, 0, tzinfo=datetime.timezone.utc)

# JSON projection for jq verification (stringify temporal values).
json_view = {
    "plain_int": data["plain_int"],
    "neg_int": data["neg_int"],
    "plain_float": data["plain_float"],
    "sci_float": data["sci_float"],
    "truth": data["truth"],
    "falsy": data["falsy"],
    "nullable": data["nullable"],
    "the_date": data["the_date"].isoformat(),
    "the_datetime": data["the_datetime"].isoformat(),
}
with open(dst, "w", encoding="utf-8") as fh:
    json.dump(json_view, fh)

print("TYPES_OK")
PY

jq -e '.plain_int == 42 and (.plain_int | type) == "number"' "$tmpdir/types.json" >/dev/null
jq -e '.neg_int == -7' "$tmpdir/types.json" >/dev/null
jq -e '.plain_float == 3.5' "$tmpdir/types.json" >/dev/null
jq -e '.sci_float == 1500' "$tmpdir/types.json" >/dev/null
jq -e '.truth == true and .falsy == false' "$tmpdir/types.json" >/dev/null
jq -e '.nullable == null' "$tmpdir/types.json" >/dev/null
jq -e '.the_date == "2024-05-17"' "$tmpdir/types.json" >/dev/null
jq -e '.the_datetime | startswith("2024-05-17T08:30:00")' "$tmpdir/types.json" >/dev/null
echo "OK"
