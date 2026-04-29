#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-dump-unicode
# @title: PyYAML unicode dump
# @description: Dumps Unicode text with PyYAML and verifies non-ASCII content is preserved.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-dump-unicode"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

dumped = yaml.safe_dump({'name': 'caf\u00e9'}, allow_unicode=True)
assert 'caf\u00e9' in dumped
print(dumped.strip())
PY
