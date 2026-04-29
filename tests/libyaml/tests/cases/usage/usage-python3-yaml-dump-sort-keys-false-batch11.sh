#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-sort-keys-false-batch11
# @title: PyYAML dump sort keys false
# @description: Dumps a mapping through PyYAML while preserving insertion order.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-sort-keys-false-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id"
import re
import sys
import yaml

case_id = sys.argv[1]

text = yaml.safe_dump({'b': 1, 'a': 2}, sort_keys=False)
assert text.splitlines()[0].startswith('b:')
print(text, end='')
PYCASE
