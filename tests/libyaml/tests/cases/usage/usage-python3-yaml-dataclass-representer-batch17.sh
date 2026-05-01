#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dataclass-representer-batch17
# @title: PyYAML custom representer serializes a dataclass via asdict
# @description: Registers a SafeDumper representer that converts a Python dataclass instance into its asdict mapping, dumps a list of two instances, and verifies both are emitted as plain YAML mappings that round-trip back through yaml.safe_load.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dataclass-representer-batch17"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import dataclasses
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

@dataclasses.dataclass
class Point:
    x: int
    y: int
    label: str

class DataclassDumper(yaml.SafeDumper):
    pass

def represent_dataclass(dumper, instance):
    return dumper.represent_mapping(
        "tag:yaml.org,2002:map",
        dataclasses.asdict(instance),
    )

DataclassDumper.add_representer(Point, represent_dataclass)

points = [Point(1, 2, "origin"), Point(-3, 5, "peak")]
text = yaml.dump(points, Dumper=DataclassDumper, default_flow_style=False, sort_keys=False)

assert "label: origin" in text, text
assert "label: peak" in text, text
assert "x: 1" in text and "y: 2" in text, text
assert "x: -3" in text and "y: 5" in text, text

# Round-trip yields plain dicts (constructor side is generic).
loaded = yaml.safe_load(text)
assert loaded == [
    {"x": 1, "y": 2, "label": "origin"},
    {"x": -3, "y": 5, "label": "peak"},
], loaded

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "label: origin"
validator_assert_contains "$tmpdir/out.yaml" "label: peak"
echo "OK"
