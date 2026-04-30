#!/usr/bin/env bash
# @testcase: usage-python3-yaml-compose-empty-document-batch14
# @title: PyYAML compose returns None for empty document
# @description: Calls yaml.compose on an empty stream and a stream containing only directives and verifies it returns None for the empty case while compose_all yields the same number of nodes as documents.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-compose-empty-document-batch14"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml
from yaml.nodes import MappingNode, ScalarNode

case_id = sys.argv[1]
out_path = sys.argv[2]

# 1. Truly empty input: compose must return None.
empty_node = yaml.compose("")
assert empty_node is None, empty_node

# 2. Whitespace-only input: still None.
ws_node = yaml.compose("   \n\n")
assert ws_node is None, ws_node

# 3. Directives-only stream with explicit start/end produces an empty scalar (null).
directive_doc = "%YAML 1.1\n---\n...\n"
dir_node = yaml.compose(directive_doc)
assert isinstance(dir_node, ScalarNode), dir_node
assert dir_node.tag == "tag:yaml.org,2002:null", dir_node.tag
assert dir_node.value == "", dir_node.value

# 4. compose_all on an empty stream yields zero documents.
all_empty = list(yaml.compose_all(""))
assert all_empty == [], all_empty

# 5. compose_all on three explicit docs yields three nodes, the middle one a null.
multi = "---\nkey: value\n---\n---\nfoo: bar\n"
nodes = list(yaml.compose_all(multi))
assert len(nodes) == 3, [n.tag for n in nodes]
assert isinstance(nodes[0], MappingNode), nodes[0]
assert nodes[1].tag == "tag:yaml.org,2002:null", nodes[1].tag
assert isinstance(nodes[2], MappingNode), nodes[2]

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(f"empty={empty_node!r}\n")
    fh.write(f"ws={ws_node!r}\n")
    fh.write(f"dir_tag={dir_node.tag}\n")
    fh.write(f"all_empty_len={len(all_empty)}\n")
    fh.write(f"multi_len={len(nodes)}\n")

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "empty=None"
validator_assert_contains "$tmpdir/out" "all_empty_len=0"
validator_assert_contains "$tmpdir/out" "multi_len=3"
echo "OK"
