#!/usr/bin/env bash
# @testcase: usage-python3-yaml-compose-node
# @title: PyYAML compose node
# @description: Composes YAML into a node tree with PyYAML and verifies the root mapping node.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-compose-node"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

node = yaml.compose('root:\n  child: 1\n')
assert node.value[0][0].value == 'root'
print(node.tag)
PY
