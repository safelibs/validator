#!/usr/bin/env bash
# @testcase: usage-python3-yaml-folded-scalar
# @title: PyYAML folded scalar
# @description: Loads a folded block scalar with PyYAML and verifies newline folding behavior.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-folded-scalar"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

data = yaml.safe_load('text: >\n  alpha\n  beta\n')
assert data['text'] == 'alpha beta\n'
print(data['text'].strip())
PY
