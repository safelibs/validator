#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-quoted-yes-string-batch14
# @title: PyYAML safe_load quoted vs unquoted yes/no
# @description: Loads a mapping where yes, no, on, off appear both unquoted and quoted and verifies that PyYAML's bundled YAML 1.1-style bool resolver still coerces unquoted yes/no/on/off to Python bools while quoted forms are forced to strings. Confirms quoting is the only safe way to keep these tokens as strings under safe_load on Ubuntu 24.04.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-quoted-yes-string-batch14"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

doc = (
    "unquoted_yes: yes\n"
    "unquoted_no: no\n"
    "unquoted_on: on\n"
    "unquoted_off: off\n"
    "quoted_yes: \"yes\"\n"
    "quoted_no: 'no'\n"
    "true_bool: true\n"
    "false_bool: false\n"
)

data = yaml.safe_load(doc)

# Ubuntu 24.04 ships PyYAML with the YAML 1.1 implicit-bool resolver
# active for SafeLoader, so unquoted yes/no/on/off coerce to bools.
assert data["unquoted_yes"] is True, data
assert data["unquoted_no"] is False, data
assert data["unquoted_on"] is True, data
assert data["unquoted_off"] is False, data

# Quoting forces the scalar through the str resolver instead.
assert data["quoted_yes"] == "yes", data
assert isinstance(data["quoted_yes"], str), data
assert data["quoted_no"] == "no", data
assert isinstance(data["quoted_no"], str), data

# true/false remain bools regardless.
assert data["true_bool"] is True, data
assert data["false_bool"] is False, data

with open(out_path, "w", encoding="utf-8") as fh:
    for key, value in data.items():
        fh.write(f"{key}={type(value).__name__}:{value!r}\n")

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "unquoted_yes=bool:True"
validator_assert_contains "$tmpdir/out" "quoted_yes=str:'yes'"
validator_assert_contains "$tmpdir/out" "true_bool=bool:True"
echo "OK"
