#!/usr/bin/env bash
# @testcase: usage-python3-yaml-datetime-safedump-roundtrip-batch18
# @title: PyYAML safe_dump and safe_load round-trip datetime.datetime via the timestamp tag
# @description: Calls yaml.safe_dump on a dict whose values are a datetime.datetime and a datetime.date, verifies the emitted text uses the canonical ISO 8601 form (no quoting), and reloads the document via yaml.safe_load to confirm the values come back as the original datetime / date Python objects with full second-precision equality.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-datetime-safedump-roundtrip-batch18"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import datetime
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

dt = datetime.datetime(2026, 5, 1, 12, 30, 45)
d = datetime.date(2026, 1, 7)
data = {"when": dt, "day": d, "label": "example"}

text = yaml.safe_dump(data, default_flow_style=False, sort_keys=True)

# ISO 8601 forms emitted by the default yaml timestamp representer.
assert "when: 2026-05-01 12:30:45" in text, text
assert "day: 2026-01-07" in text, text
# The timestamps are NOT quoted -- they match the implicit timestamp tag.
assert "'2026-05-01" not in text, text
assert "\"2026-05-01" not in text, text

loaded = yaml.safe_load(text)
assert loaded["when"] == dt, loaded
assert isinstance(loaded["when"], datetime.datetime), type(loaded["when"])
assert loaded["day"] == d, loaded
# datetime.datetime is itself a date subclass, so check the exact type.
assert type(loaded["day"]) is datetime.date, type(loaded["day"])
assert loaded["label"] == "example", loaded

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "when: 2026-05-01 12:30:45"
validator_assert_contains "$tmpdir/out.yaml" "day: 2026-01-07"
echo "OK"
