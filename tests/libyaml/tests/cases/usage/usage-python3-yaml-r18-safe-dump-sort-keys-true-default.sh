#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r18-safe-dump-sort-keys-true-default
# @title: PyYAML safe_dump sorts mapping keys lexicographically by default
# @description: Dumps a Python dict with unsorted insertion-order keys via yaml.safe_dump with default options and asserts the output line order is 'a:', 'b:', 'c:' — pinning the default sort_keys=True behavior.
# @timeout: 60
# @tags: usage, python3-yaml, safe-dump, sort-keys, r18
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = {'c': 1, 'a': 2, 'b': 3}
out = yaml.safe_dump(data)
keys_in_order = [line.split(':', 1)[0] for line in out.splitlines() if line and not line.startswith(' ')]
assert keys_in_order == ['a', 'b', 'c'], (keys_in_order, out)
PY
