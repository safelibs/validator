#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-nested-map
# @title: PyYAML safe load nested map
# @description: Safely loads a nested YAML mapping with PyYAML and verifies a deeply nested scalar value.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-nested-map"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import yaml
from yaml.events import AliasEvent, MappingStartEvent, ScalarEvent
from yaml.tokens import AliasToken, AnchorToken, ScalarToken

case_id = sys.argv[1]
tmpdir = sys.argv[2]

payload = yaml.safe_load(
    "root:\n"
    "  child:\n"
    "    flag: true\n"
    "    items:\n"
    "      - 7\n"
    "      - 9\n"
)
assert payload == {"root": {"child": {"flag": True, "items": [7, 9]}}}
assert isinstance(payload["root"]["child"]["flag"], bool)
print(payload["root"]["child"]["items"][1])
PY
