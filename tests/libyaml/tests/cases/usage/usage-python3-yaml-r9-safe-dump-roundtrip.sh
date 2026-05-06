#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r9-safe-dump-roundtrip
# @title: PyYAML safe_dump roundtrip preserves dict
# @description: Dumps a Python dict via yaml.safe_dump and reloads it with yaml.safe_load, asserting equality.
# @timeout: 60
# @tags: usage, python3-yaml
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import yaml
data = {
    'name': 'demo',
    'count': 7,
    'enabled': True,
    'tags': ['x', 'y', 'z'],
    'meta': {'a': 1, 'b': 2.5},
}
text = yaml.safe_dump(data, sort_keys=True)
restored = yaml.safe_load(text)
assert restored == data, (restored, data)
PY
