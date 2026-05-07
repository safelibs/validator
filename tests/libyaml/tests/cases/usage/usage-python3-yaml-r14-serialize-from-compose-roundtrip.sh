#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r14-serialize-from-compose-roundtrip
# @title: PyYAML serialize consumes a node tree from compose and reproduces a load-equivalent document
# @description: Composes a mapping into a Node tree with yaml.compose, feeds the root node into yaml.serialize, and asserts the regenerated YAML text loads back to the same Python dict as the original — exercising the compose/serialize pair which sits one level above parse/emit and one level below load/dump.
# @timeout: 60
# @tags: usage, python3-yaml, serialize, compose, node
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = "k1: v1\nk2: 42\n"
node = yaml.compose(src)
# compose returns the root node of the document; for a mapping that is a MappingNode.
assert type(node).__name__ == 'MappingNode', type(node)
out = yaml.serialize(node)
back = yaml.safe_load(out)
assert back == {'k1': 'v1', 'k2': 42}, back
PY
