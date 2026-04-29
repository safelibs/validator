#!/usr/bin/env bash
# @testcase: usage-python3-yaml-block-scalar
# @title: PyYAML block scalar
# @description: Loads a YAML block scalar with PyYAML and verifies multiline content.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-block-scalar"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

data = yaml.safe_load('text: |\n  alpha\n  beta\n')
assert data['text'] == 'alpha\nbeta\n'
print(data['text'].splitlines()[1])
PY
