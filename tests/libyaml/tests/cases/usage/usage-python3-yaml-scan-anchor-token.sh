#!/usr/bin/env bash
# @testcase: usage-python3-yaml-scan-anchor-token
# @title: PyYAML scan anchor token
# @description: Scans YAML tokens with PyYAML and verifies an anchor token is emitted for anchored input.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-scan-anchor-token"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import yaml
from yaml.events import AliasEvent, MappingStartEvent, ScalarEvent
from yaml.tokens import AliasToken, AnchorToken, ScalarToken

case_id = sys.argv[1]
tmpdir = sys.argv[2]

tokens = list(yaml.scan("root: &anchor alpha\nref: *anchor\n"))
names = [type(token).__name__ for token in tokens]
assert any(isinstance(token, AnchorToken) and token.value == "anchor" for token in tokens)
assert any(isinstance(token, AliasToken) and token.value == "anchor" for token in tokens)
assert any(isinstance(token, ScalarToken) and token.value == "alpha" for token in tokens)
print(",".join(names))
PY
