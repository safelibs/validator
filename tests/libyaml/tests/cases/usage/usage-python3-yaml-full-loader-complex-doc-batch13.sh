#!/usr/bin/env bash
# @testcase: usage-python3-yaml-full-loader-complex-doc-batch13
# @title: PyYAML FullLoader on a complex document
# @description: Loads a complex document with mixed mappings, sequences, dates, and bools using yaml.FullLoader and verifies the resulting Python types.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-full-loader-complex-doc-batch13"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml

case_id = sys.argv[1]

doc = """
project: validator
released: 2024-05-01
active: true
contributors:
  - name: alice
    commits: 12
  - name: bob
    commits: 7
ratings:
  ux: 4.5
  perf: 3.0
tags: [python, yaml, ci]
"""

loaded = yaml.load(doc, Loader=yaml.FullLoader)
assert isinstance(loaded, dict), type(loaded)
assert loaded["project"] == "validator"
assert loaded["released"] == datetime.date(2024, 5, 1)
assert loaded["active"] is True
assert isinstance(loaded["contributors"], list) and len(loaded["contributors"]) == 2
assert loaded["contributors"][0] == {"name": "alice", "commits": 12}
assert loaded["ratings"]["ux"] == 4.5
assert loaded["tags"] == ["python", "yaml", "ci"]

print("PROJECT", loaded["project"])
print("RELEASED", loaded["released"])
print("ACTIVE", loaded["active"])
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "PROJECT validator"
validator_assert_contains "$tmpdir/out" "RELEASED 2024-05-01"
validator_assert_contains "$tmpdir/out" "ACTIVE True"
validator_assert_contains "$tmpdir/out" "OK"
echo "OK"
