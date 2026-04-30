#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-block-strip-chomp-batch16
# @title: PyYAML SafeLoader on |- strips trailing newlines
# @description: Loads a literal block scalar with the strip chomping indicator (|-) through yaml.safe_load and verifies all trailing newlines are removed from the resulting string while interior newlines are preserved.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-block-strip-chomp-batch16"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

doc = "value: |-\n  alpha\n  beta\n  gamma\n\n\n"
data = yaml.safe_load(doc)

# |- strips every trailing newline.
assert data == {"value": "alpha\nbeta\ngamma"}, repr(data)
assert not data["value"].endswith("\n"), repr(data["value"])
# Interior newlines must remain.
assert data["value"].count("\n") == 2, repr(data["value"])

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(repr(data["value"]))

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "alpha"
validator_assert_contains "$tmpdir/out" "gamma"
echo "OK"
