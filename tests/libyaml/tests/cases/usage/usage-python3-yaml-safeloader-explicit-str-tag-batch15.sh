#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safeloader-explicit-str-tag-batch15
# @title: PyYAML SafeLoader honors explicit !!str tag to force string
# @description: Loads scalars whose plain form would normally resolve to int or bool ("42", "true") but that are tagged with the explicit core schema tag !!str, and verifies SafeLoader yields a Python str whose value is the unparsed digit/word, while an untagged sibling resolves to its native int/bool.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safeloader-explicit-str-tag-batch15"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

source = (
    "tagged_int: !!str 42\n"
    "tagged_bool: !!str true\n"
    "plain_int: 42\n"
    "plain_bool: true\n"
)

data = yaml.safe_load(source)

assert data["tagged_int"] == "42", data["tagged_int"]
assert isinstance(data["tagged_int"], str), type(data["tagged_int"])
assert data["tagged_bool"] == "true", data["tagged_bool"]
assert isinstance(data["tagged_bool"], str), type(data["tagged_bool"])
# Plain (untagged) siblings resolve to their native scalar types.
assert data["plain_int"] == 42, data["plain_int"]
assert isinstance(data["plain_int"], int), type(data["plain_int"])
assert data["plain_bool"] is True, data["plain_bool"]
assert isinstance(data["plain_bool"], bool), type(data["plain_bool"])

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(f"tagged_int={data['tagged_int']!r}\n")
    fh.write(f"tagged_bool={data['tagged_bool']!r}\n")
    fh.write(f"plain_int_type={type(data['plain_int']).__name__}\n")
    fh.write(f"plain_bool_type={type(data['plain_bool']).__name__}\n")

print("STR_TAG_OK")
PYCASE

validator_assert_contains "$tmpdir/out" "tagged_int='42'"
validator_assert_contains "$tmpdir/out" "tagged_bool='true'"
validator_assert_contains "$tmpdir/out" "plain_int_type=int"
validator_assert_contains "$tmpdir/out" "plain_bool_type=bool"
echo "OK"
