#!/usr/bin/env bash
# @testcase: usage-python3-yaml-uuid-roundtrip-batch17
# @title: PyYAML round-trips uuid.UUID via custom !uuid representer and constructor
# @description: Registers SafeDumper.add_representer and SafeLoader.add_constructor for the !uuid tag against uuid.UUID, dumps and reloads a fixed UUID4 value, and verifies the loaded object is a uuid.UUID with the original hex.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-uuid-roundtrip-batch17"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import uuid
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

class UuidDumper(yaml.SafeDumper):
    pass

class UuidLoader(yaml.SafeLoader):
    pass

UUID_TAG = "!uuid"

def represent_uuid(dumper, value):
    return dumper.represent_scalar(UUID_TAG, str(value))

def construct_uuid(loader, node):
    return uuid.UUID(loader.construct_scalar(node))

UuidDumper.add_representer(uuid.UUID, represent_uuid)
UuidLoader.add_constructor(UUID_TAG, construct_uuid)

# Fixed UUID so the test is deterministic.
fixed = uuid.UUID("12345678-1234-5678-1234-567812345678")
data = {"id": fixed, "label": "fixture"}

text = yaml.dump(data, Dumper=UuidDumper, default_flow_style=False, sort_keys=True)

assert "!uuid" in text, text
assert "12345678-1234-5678-1234-567812345678" in text, text

loaded = yaml.load(text, Loader=UuidLoader)
assert isinstance(loaded["id"], uuid.UUID), type(loaded["id"])
assert loaded["id"] == fixed, loaded["id"]
assert loaded["label"] == "fixture", loaded

# safe_load (without constructor) refuses unknown !uuid tag.
import yaml as _yaml
try:
    _yaml.safe_load(text)
except _yaml.constructor.ConstructorError:
    pass
else:
    raise AssertionError("expected SafeLoader to reject !uuid without constructor")

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "!uuid"
validator_assert_contains "$tmpdir/out.yaml" "12345678-1234-5678-1234-567812345678"
echo "OK"
