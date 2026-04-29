#!/usr/bin/env bash
# @testcase: usage-python3-yaml-full-load-hex-int
# @title: PyYAML full load hex int
# @description: Fully loads a hexadecimal scalar with PyYAML and verifies it is decoded to the expected integer value.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-full-load-hex-int"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import yaml
from yaml.events import AliasEvent, MappingStartEvent, ScalarEvent
from yaml.tokens import AliasToken, AnchorToken, ScalarToken

case_id = sys.argv[1]
tmpdir = sys.argv[2]

payload = yaml.full_load("value: 0x10\n")
assert payload["value"] == 16
assert isinstance(payload["value"], int)
print(payload["value"])
PY
