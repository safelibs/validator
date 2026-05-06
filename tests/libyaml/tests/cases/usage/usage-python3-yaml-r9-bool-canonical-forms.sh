#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r9-bool-canonical-forms
# @title: PyYAML safe_load resolves canonical bool tokens
# @description: Loads YAML 1.1 bool tokens 'true' and 'false' and asserts they are mapped to Python True/False, while quoted forms remain strings.
# @timeout: 60
# @tags: usage, python3-yaml
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import yaml
data = yaml.safe_load("""a: true
b: false
c: 'true'
d: "false"
""")
assert data['a'] is True
assert data['b'] is False
assert data['c'] == 'true' and isinstance(data['c'], str)
assert data['d'] == 'false' and isinstance(data['d'], str)
PY
