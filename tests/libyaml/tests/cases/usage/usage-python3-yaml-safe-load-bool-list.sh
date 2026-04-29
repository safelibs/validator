#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-bool-list
# @title: PyYAML safe load bool list
# @description: Safely loads a YAML boolean list with PyYAML and verifies the decoded truth values.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-bool-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import yaml
from yaml.events import AliasEvent, MappingStartEvent, ScalarEvent
from yaml.tokens import AliasToken, AnchorToken, ScalarToken

case_id = sys.argv[1]
tmpdir = sys.argv[2]

payload = yaml.safe_load("- true\n- false\n- true\n")
assert payload == [True, False, True]
assert [type(item).__name__ for item in payload] == ["bool", "bool", "bool"]
print(",".join("true" if item else "false" for item in payload))
PY
