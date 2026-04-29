#!/usr/bin/env bash
# @testcase: usage-python3-yaml-scan-tokens
# @title: PyYAML token scanner
# @description: Scans YAML tokens with PyYAML and verifies scalar tokens are emitted.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-scan-tokens"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

tokens = list(yaml.scan('name: alpha\n'))
assert any(isinstance(token, ScalarToken) and token.value == 'alpha' for token in tokens)
print('tokens', len(tokens))
PY
