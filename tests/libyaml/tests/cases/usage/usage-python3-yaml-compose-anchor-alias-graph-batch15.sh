#!/usr/bin/env bash
# @testcase: usage-python3-yaml-compose-anchor-alias-graph-batch15
# @title: PyYAML compose preserves anchor identity in resulting Node graph
# @description: Composes a document that uses an anchor on a mapping and an alias referencing it, then walks the produced yaml.nodes graph and verifies the alias resolves to the same Node object as the anchored mapping (object identity, not just equality).
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-compose-anchor-alias-graph-batch15"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml
from yaml.nodes import MappingNode

case_id = sys.argv[1]
out_path = sys.argv[2]

source = (
    "base: &shared\n"
    "  host: example.org\n"
    "  port: 80\n"
    "copy: *shared\n"
)
root = yaml.compose(source)
assert isinstance(root, MappingNode), type(root)

# Pull the value nodes for the two top-level keys.
mapping = {}
for key_node, value_node in root.value:
    mapping[key_node.value] = value_node

base_node = mapping["base"]
copy_node = mapping["copy"]

# Anchor and alias must yield the same object in the composed Node graph.
assert base_node is copy_node, (id(base_node), id(copy_node))
assert isinstance(base_node, MappingNode), type(base_node)
# yaml.compose collapses an alias to a reference to the same Node instance.
assert id(base_node) == id(copy_node)

# Inspect inner key/value scalars.
inner = {k.value: v.value for k, v in base_node.value}
assert inner == {"host": "example.org", "port": "80"}, inner

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(f"identity={base_node is copy_node}\n")
    fh.write(f"id_equal={id(base_node) == id(copy_node)}\n")
    fh.write(f"inner={inner!r}\n")

print("COMPOSE_GRAPH_OK")
PYCASE

validator_assert_contains "$tmpdir/out" "identity=True"
validator_assert_contains "$tmpdir/out" "id_equal=True"
echo "OK"
