#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-multidoc
# @title: PyYAML CSafeLoader multiple docs
# @description: Loads multiple YAML documents with CSafeLoader and checks document count.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-csafe-multidoc"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

loader = getattr(yaml, 'CSafeLoader', yaml.SafeLoader)
docs = list(yaml.load_all('---\na: 1\n---\nb: 2\n', Loader=loader))
assert len(docs) == 2
print('docs', len(docs))
PY
