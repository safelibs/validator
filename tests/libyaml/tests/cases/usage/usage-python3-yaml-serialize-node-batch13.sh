#!/usr/bin/env bash
# @testcase: usage-python3-yaml-serialize-node-batch13
# @title: PyYAML serialize a constructed Node tree
# @description: Builds a MappingNode/ScalarNode tree by hand and serializes it with yaml.serialize, verifying the emitted YAML round-trips through safe_load.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-serialize-node-batch13"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml
from yaml.nodes import MappingNode, ScalarNode

case_id = sys.argv[1]
dst = sys.argv[2]

key = ScalarNode(tag="tag:yaml.org,2002:str", value="greeting")
val = ScalarNode(tag="tag:yaml.org,2002:str", value="hello")
root = MappingNode(tag="tag:yaml.org,2002:map", value=[(key, val)])

text = yaml.serialize(root)
with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

assert "greeting" in text, text
assert "hello" in text, text

loaded = yaml.safe_load(text)
assert loaded == {"greeting": "hello"}, loaded

print("LEN", len(text))
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "greeting"
validator_assert_contains "$tmpdir/out.yaml" "hello"
echo "OK"
