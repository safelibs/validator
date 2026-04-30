#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-default-style-single-quote-batch12
# @title: PyYAML dump default_style single quote
# @description: Dumps mapping values with yaml.dump default_style="'" and verifies every scalar value is wrapped in single quotes.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-default-style-single-quote-batch12"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

data = {"a": "alpha", "b": "bravo", "c": "charlie"}
text = yaml.dump(data, default_style="'", default_flow_style=False, sort_keys=True)

# Every value line should contain single-quoted scalars.
value_lines = [ln for ln in text.splitlines() if ":" in ln]
assert len(value_lines) == 3, text
for ln in value_lines:
    after_colon = ln.split(":", 1)[1].strip()
    assert after_colon.startswith("'") and after_colon.endswith("'"), ln
    # Keys are also single-quoted under default_style="'".
    before_colon = ln.split(":", 1)[0]
    assert before_colon.startswith("'") and before_colon.endswith("'"), ln

assert yaml.safe_load(text) == data

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "'alpha'"
validator_assert_contains "$tmpdir/out.yaml" "'bravo'"
validator_assert_contains "$tmpdir/out.yaml" "'charlie'"
echo "OK"
