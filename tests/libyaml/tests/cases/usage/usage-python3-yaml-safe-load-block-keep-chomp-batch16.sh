#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-block-keep-chomp-batch16
# @title: PyYAML SafeLoader on |+ block scalar keeps trailing newlines
# @description: Loads a literal block scalar with the keep chomping indicator (|+) through yaml.safe_load and verifies all trailing newlines after the content are preserved verbatim.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-block-keep-chomp-batch16"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

doc = "value: |+\n  alpha\n  beta\n\n\n"
data = yaml.safe_load(doc)

# |+ keeps the trailing newlines that follow the block content. PyYAML
# preserves: one terminator after each content line, plus the two empty
# lines after - giving four newlines total ("alpha\nbeta\n\n\n").
assert data == {"value": "alpha\nbeta\n\n\n"}, repr(data)
assert data["value"].endswith("\n\n\n"), repr(data["value"])
assert data["value"].count("\n") == 4, repr(data["value"])

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(repr(data["value"]))

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "alpha"
validator_assert_contains "$tmpdir/out" "beta"
echo "OK"
