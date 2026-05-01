#!/usr/bin/env bash
# @testcase: usage-python3-yaml-namedtuple-representer-batch17
# @title: PyYAML custom representer serializes a NamedTuple as a sequence
# @description: Registers a SafeDumper representer that emits a typing.NamedTuple instance as a flow sequence of its field values, dumps two instances, and verifies the output is parsed back into the same Python tuple values via yaml.safe_load.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-namedtuple-representer-batch17"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
from typing import NamedTuple
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

class Vec3(NamedTuple):
    x: int
    y: int
    z: int

class TupleDumper(yaml.SafeDumper):
    pass

def represent_vec3(dumper, instance):
    # Emit as flow sequence so the test pins the wire format.
    return dumper.represent_sequence(
        "tag:yaml.org,2002:seq",
        list(instance),
        flow_style=True,
    )

TupleDumper.add_representer(Vec3, represent_vec3)

data = {"a": Vec3(1, 2, 3), "b": Vec3(-4, 0, 7)}
text = yaml.dump(data, Dumper=TupleDumper, default_flow_style=False, sort_keys=True)

assert "a: [1, 2, 3]" in text, text
assert "b: [-4, 0, 7]" in text, text

# Generic safe_load gives plain lists back.
loaded = yaml.safe_load(text)
assert loaded == {"a": [1, 2, 3], "b": [-4, 0, 7]}, loaded

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "a: [1, 2, 3]"
validator_assert_contains "$tmpdir/out.yaml" "b: [-4, 0, 7]"
echo "OK"
