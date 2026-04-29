#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-dump-all-three-batch11
# @title: PyYAML dump all three documents
# @description: Dumps three explicit YAML documents through PyYAML.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-dump-all-three-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id"
import re
import sys
import yaml

case_id = sys.argv[1]

text = yaml.safe_dump_all([{'a': 1}, {'b': 2}, {'c': 3}], explicit_start=True)
assert text.count('---') == 3
print(text, end='')
PYCASE
