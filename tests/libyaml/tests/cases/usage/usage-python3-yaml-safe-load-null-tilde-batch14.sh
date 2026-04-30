#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-null-tilde-batch14
# @title: PyYAML safe_load on tilde null shorthand
# @description: Loads each of the canonical null spellings (~, null, Null, NULL, empty) through yaml.safe_load and verifies they all resolve to Python None while a quoted "~" remains a string.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-null-tilde-batch14"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

doc = (
    "tilde: ~\n"
    "spelled: null\n"
    "title: Null\n"
    "shout: NULL\n"
    "empty:\n"
    "quoted_tilde: \"~\"\n"
)

data = yaml.safe_load(doc)

assert data["tilde"] is None, data
assert data["spelled"] is None, data
assert data["title"] is None, data
assert data["shout"] is None, data
assert data["empty"] is None, data
# A quoted tilde stays a literal string.
assert data["quoted_tilde"] == "~", data

with open(out_path, "w", encoding="utf-8") as fh:
    for key in ("tilde", "spelled", "title", "shout", "empty", "quoted_tilde"):
        fh.write(f"{key}={data[key]!r}\n")

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "tilde=None"
validator_assert_contains "$tmpdir/out" "quoted_tilde='~'"
echo "OK"
