#!/usr/bin/env bash
# @testcase: usage-python3-yaml-merge-keys
# @title: PyYAML merge keys
# @description: Loads YAML merge keys with PyYAML and verifies inherited mapping values.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-merge-keys"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

data = yaml.safe_load('base: &base {name: alpha, count: 2}\nitem: {<<: *base, count: 3}\n')
assert data['item']['name'] == 'alpha' and data['item']['count'] == 3
print(data['item']['name'], data['item']['count'])
PY
