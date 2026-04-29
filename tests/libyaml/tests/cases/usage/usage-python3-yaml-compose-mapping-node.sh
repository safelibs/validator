#!/usr/bin/env bash
# @testcase: usage-python3-yaml-compose-mapping-node
# @title: PyYAML compose mapping node
# @description: Exercises pyyaml compose mapping node through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-compose-mapping-node"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id"
import sys
import yaml
from yaml.events import MappingStartEvent, ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

node = yaml.compose('root:\n  child: alpha\n')
assert node.value[0][0].value == 'root'
print(node.value[0][0].value)
PY
