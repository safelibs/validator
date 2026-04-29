#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-dump-width
# @title: PyYAML safe dump width
# @description: Safely dumps YAML with a narrow width setting and verifies the emitted text still contains the expected sequence values.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-dump-width"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import yaml
from yaml.events import AliasEvent, MappingStartEvent, ScalarEvent
from yaml.tokens import AliasToken, AnchorToken, ScalarToken

case_id = sys.argv[1]
tmpdir = sys.argv[2]

value = ["alphabet", "betatron", "gammawave", "deltaforce"]
text = yaml.safe_dump(value, width=20, default_flow_style=True)
lines = [line for line in text.splitlines() if line]
assert len(lines) >= 2
assert lines[1].startswith("  ")
assert yaml.safe_load(text) == value
print(len(lines), lines[1])
PY
