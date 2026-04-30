#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-nested-map-of-lists-of-dicts-batch16
# @title: PyYAML yaml.dump nested mapping of lists of dicts uses canonical block layout
# @description: Dumps a mapping whose values are lists of dictionaries with default block style and verifies the exact indentation pattern (top-level key, sequence dash, and nested mapping keys) and round-trips through safe_load.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-nested-map-of-lists-of-dicts-batch16"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

value = {
    "servers": [
        {"name": "alpha", "port": 8080},
        {"name": "beta", "port": 8081},
    ],
    "clients": [
        {"name": "gamma", "weight": 1},
    ],
}

text = yaml.dump(value, default_flow_style=False, sort_keys=False)

# The PyYAML default emitter does NOT indent sequence dashes under a mapping
# key; the dash sits at column 0 relative to its parent key. Verify that
# exact layout for the "servers" branch.
expected_servers_block = (
    "servers:\n"
    "- name: alpha\n"
    "  port: 8080\n"
    "- name: beta\n"
    "  port: 8081\n"
)
expected_clients_block = (
    "clients:\n"
    "- name: gamma\n"
    "  weight: 1\n"
)

assert expected_servers_block in text, text
assert expected_clients_block in text, text

# Round-trip preserves the structure exactly.
assert yaml.safe_load(text) == value, text

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("OK")
PYCASE

grep -q '^servers:' "$tmpdir/out.yaml"
grep -q '^- name: alpha' "$tmpdir/out.yaml"
grep -q '^  port: 8080' "$tmpdir/out.yaml"
grep -q '^clients:' "$tmpdir/out.yaml"
grep -q '^- name: gamma' "$tmpdir/out.yaml"
echo "OK"
