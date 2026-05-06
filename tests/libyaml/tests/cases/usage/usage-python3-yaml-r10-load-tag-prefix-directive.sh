#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r10-load-tag-prefix-directive
# @title: PyYAML compose resolves !ex! prefix from input %TAG directive
# @description: Composes a document containing a %TAG !ex! tag:example.com,2026: directive and a scalar tagged !ex!greeting, then verifies the composed ScalarNode tag string equals the fully-resolved tag:example.com,2026:greeting URI rather than the !ex!greeting handle form.
# @timeout: 60
# @tags: usage, python3-yaml, tag-directive
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
from yaml.nodes import MappingNode, ScalarNode

text = (
    "%TAG !ex! tag:example.com,2026:\n"
    "---\n"
    "value: !ex!greeting hello\n"
)
node = yaml.compose(text)
assert isinstance(node, MappingNode), type(node)
items = dict((k.value, v) for k, v in node.value)
val_node = items['value']
assert isinstance(val_node, ScalarNode), type(val_node)
assert val_node.tag == 'tag:example.com,2026:greeting', val_node.tag
assert val_node.value == 'hello', val_node.value
PY
