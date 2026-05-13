#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r16-compose-node-tag-mapping
# @title: PyYAML compose returns a MappingNode whose .tag is the canonical map tag and which carries the expected number of key/value pairs
# @description: Calls yaml.compose on a two-key mapping document, asserts the returned object is a MappingNode whose tag equals 'tag:yaml.org,2002:map' and whose .value sequence has length 2 (one entry per key/value pair).
# @timeout: 60
# @tags: usage, python3-yaml, compose, node
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
from yaml.nodes import MappingNode, ScalarNode

doc = "alpha: 1\nbravo: two\n"
node = yaml.compose(doc)
assert isinstance(node, MappingNode), type(node)
assert node.tag == 'tag:yaml.org,2002:map', node.tag
assert len(node.value) == 2, node.value
# Each pair is (key_node, value_node) where both are ScalarNodes here.
for key_node, value_node in node.value:
    assert isinstance(key_node, ScalarNode), type(key_node)
    assert isinstance(value_node, ScalarNode), type(value_node)
PY
