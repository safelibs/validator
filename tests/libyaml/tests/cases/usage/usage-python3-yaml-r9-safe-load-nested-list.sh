#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r9-safe-load-nested-list
# @title: PyYAML safe_load handles nested lists of dicts
# @description: Loads a small block-style YAML document with a list of mappings via yaml.safe_load and asserts the structure and types match.
# @timeout: 60
# @tags: usage, python3-yaml
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import yaml
data = yaml.safe_load("""items:
  - name: alpha
    score: 10
  - name: beta
    score: 20
""")
assert isinstance(data, dict), type(data)
assert isinstance(data['items'], list), type(data['items'])
assert len(data['items']) == 2
assert data['items'][0] == {'name': 'alpha', 'score': 10}
assert data['items'][1]['score'] == 20
PY
