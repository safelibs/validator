#!/usr/bin/env bash
# @testcase: usage-python3-yaml-serialize-all-multiple-nodes-batch14
# @title: PyYAML serialize_all over multiple Node trees
# @description: Builds three Node trees by hand and emits them as a single YAML stream with yaml.serialize_all, then verifies the stream contains three explicit document markers and round-trips through yaml.safe_load_all.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-serialize-all-multiple-nodes-batch14"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/stream.yaml"
import sys
import yaml
from yaml.nodes import MappingNode, ScalarNode, SequenceNode

case_id = sys.argv[1]
dst = sys.argv[2]

STR = "tag:yaml.org,2002:str"
INT = "tag:yaml.org,2002:int"
MAP = "tag:yaml.org,2002:map"
SEQ = "tag:yaml.org,2002:seq"

def s(value, tag=STR):
    return ScalarNode(tag=tag, value=str(value))

# Document 1: a mapping
doc1 = MappingNode(tag=MAP, value=[(s("name"), s("alpha")), (s("count"), s("1", INT))])

# Document 2: a sequence
doc2 = SequenceNode(tag=SEQ, value=[s("x"), s("y"), s("z")], flow_style=False)

# Document 3: a single scalar
doc3 = s("plain")

text = yaml.serialize_all([doc1, doc2, doc3], explicit_start=True, explicit_end=True)
with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

assert text.count("---") == 3, text
assert text.count("...") == 3, text

loaded = list(yaml.safe_load_all(text))
assert len(loaded) == 3, loaded
assert loaded[0] == {"name": "alpha", "count": 1}, loaded
assert loaded[1] == ["x", "y", "z"], loaded
assert loaded[2] == "plain", loaded

print("DOCS", len(loaded))
print("OK")
PYCASE

# Confirm three doc start markers live in the file.
python3 - <<'PYCHECK' "$tmpdir/stream.yaml"
import sys
text = open(sys.argv[1]).read()
assert text.count("---") == 3, text
assert text.count("...") == 3, text
print("MARKERS_OK")
PYCHECK

validator_assert_contains "$tmpdir/stream.yaml" "alpha"
validator_assert_contains "$tmpdir/stream.yaml" "plain"
echo "OK"
