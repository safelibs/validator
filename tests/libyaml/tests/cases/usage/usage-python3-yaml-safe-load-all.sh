#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-all
# @title: PyYAML safe_load_all
# @description: Loads multiple YAML documents with safe_load_all and verifies both documents are returned.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-all"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

docs = list(yaml.safe_load_all('---\na: 1\n---\nb: 2\n'))
assert docs == [{'a': 1}, {'b': 2}]
print('docs', len(docs))
PY
