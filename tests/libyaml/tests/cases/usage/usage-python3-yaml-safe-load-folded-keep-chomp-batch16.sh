#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-folded-keep-chomp-batch16
# @title: PyYAML SafeLoader on >+ folded keep preserves trailing newlines
# @description: Loads a folded block scalar with the keep chomping indicator (>+) through yaml.safe_load and verifies that interior newlines are folded into spaces while every trailing newline is preserved verbatim.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-folded-keep-chomp-batch16"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

doc = "value: >+\n  alpha\n  beta\n  gamma\n\n\n"
data = yaml.safe_load(doc)

# Folded scalars convert single newlines into spaces between words, and >+
# preserves trailing newlines after the folded text.
assert data == {"value": "alpha beta gamma\n\n\n"}, repr(data)
assert data["value"].startswith("alpha beta gamma"), repr(data["value"])
assert data["value"].endswith("\n\n\n"), repr(data["value"])

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(repr(data["value"]))

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "alpha beta gamma"
echo "OK"
