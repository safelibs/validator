#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-explicit-seq-tag-batch14
# @title: PyYAML serialize emits explicit non-default sequence tag
# @description: Builds a yaml.SequenceNode whose tag is a non-default custom tag (!myseq), serializes it through yaml.serialize, and verifies the !myseq tag literal appears verbatim in the rendered YAML alongside the two scalar payloads. The default !!seq tag is elided by the emitter when the resolver would already infer it; this exercises the explicit-tag emission path that round-trips the tag literal into the output stream.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-explicit-seq-tag-batch14"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml
from yaml.nodes import ScalarNode, SequenceNode

case_id = sys.argv[1]
dst = sys.argv[2]

items = [
    ScalarNode(tag="tag:yaml.org,2002:str", value="alpha"),
    ScalarNode(tag="tag:yaml.org,2002:str", value="beta"),
]
# Custom local tag — the emitter must spell it out because the default
# resolver would otherwise infer !!seq.
seq = SequenceNode(tag="!myseq", value=items, flow_style=False)

text = yaml.serialize(seq)
with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

assert "!myseq" in text, text
assert "alpha" in text and "beta" in text, text

# Round-trip with a loader that maps !myseq back to a Python list.
class MySeqLoader(yaml.SafeLoader):
    pass

def construct_myseq(loader, node):
    return loader.construct_sequence(node)

MySeqLoader.add_constructor("!myseq", construct_myseq)
loaded = yaml.load(text, Loader=MySeqLoader)
assert loaded == ["alpha", "beta"], loaded

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "!myseq"
validator_assert_contains "$tmpdir/out.yaml" "alpha"
echo "OK"
