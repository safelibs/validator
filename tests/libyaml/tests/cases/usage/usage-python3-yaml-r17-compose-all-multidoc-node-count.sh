#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r17-compose-all-multidoc-node-count
# @title: PyYAML yaml.compose_all materializes one Node per document in a multi-doc stream
# @description: Composes a triple-document YAML stream via yaml.compose_all, asserts the list has length 3 and that each entry is a yaml.nodes.Node instance — exercising the compose path that produces graph-of-Node objects without resolving Python values.
# @timeout: 60
# @tags: usage, python3-yaml, compose, multidoc
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
from yaml.nodes import Node

stream = "---\na: 1\n---\n- one\n- two\n---\njust-scalar\n"
nodes = list(yaml.compose_all(stream))
assert len(nodes) == 3, len(nodes)
for n in nodes:
    assert isinstance(n, Node), type(n)
PY
