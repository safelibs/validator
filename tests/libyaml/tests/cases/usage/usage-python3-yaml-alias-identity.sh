#!/usr/bin/env bash
# @testcase: usage-python3-yaml-alias-identity
# @title: PyYAML alias identity
# @description: Loads YAML aliases and verifies both references point to equivalent data.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-alias-identity"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

data = yaml.safe_load('left: &node [1, 2]\nright: *node\n')
assert data['left'] == data['right'] == [1, 2]
print(data['right'])
PY
