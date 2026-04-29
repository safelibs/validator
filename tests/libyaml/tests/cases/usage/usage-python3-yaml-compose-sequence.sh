#!/usr/bin/env bash
# @testcase: usage-python3-yaml-compose-sequence
# @title: PyYAML compose sequence
# @description: Composes a YAML sequence node with PyYAML and verifies the parsed node kind and element count.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-compose-sequence"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import yaml
from yaml.events import AliasEvent, MappingStartEvent, ScalarEvent
from yaml.tokens import AliasToken, AnchorToken, ScalarToken

case_id = sys.argv[1]
tmpdir = sys.argv[2]

node = yaml.compose("- alpha\n- beta\n")
assert node.tag == "tag:yaml.org,2002:seq"
assert [child.value for child in node.value] == ["alpha", "beta"]
print(node.tag)
PY
