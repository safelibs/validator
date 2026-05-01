#!/usr/bin/env bash
# @testcase: usage-python3-yaml-cloader-mapping-batch18
# @title: PyYAML yaml.CLoader (libyaml-backed full loader) parses a nested mapping
# @description: Exercises yaml.CLoader, the libyaml-backed C variant of the full loader, by parsing a nested mapping with a list value and a quoted string. Verifies that yaml.CLoader is available (which on Ubuntu 24.04 requires python3-yaml to have been built against libyaml) and that the parsed Python objects match the expected structure and types.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-cloader-mapping-batch18"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

# CLoader is the libyaml-backed unsafe full loader. On Ubuntu 24.04 the
# python3-yaml binding ships the C accelerators, so this attribute must
# resolve. If it is missing, the binding was built without libyaml.
assert hasattr(yaml, "CLoader"), "yaml.CLoader missing -- python3-yaml not linked against libyaml"

doc = (
    "service:\n"
    "  name: alpha\n"
    "  port: 8080\n"
    "  tags:\n"
    "    - prod\n"
    "    - east\n"
    "label: \"hello world\"\n"
)

data = yaml.load(doc, Loader=yaml.CLoader)

assert isinstance(data, dict), type(data)
assert data["service"]["name"] == "alpha", data
assert data["service"]["port"] == 8080, data
assert isinstance(data["service"]["port"], int), type(data["service"]["port"])
assert data["service"]["tags"] == ["prod", "east"], data
assert data["label"] == "hello world", data

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(f"name={data['service']['name']}\n")
    fh.write(f"port={data['service']['port']}\n")
    fh.write(f"tags={','.join(data['service']['tags'])}\n")
    fh.write(f"label={data['label']}\n")

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "name=alpha"
validator_assert_contains "$tmpdir/out" "port=8080"
validator_assert_contains "$tmpdir/out" "tags=prod,east"
validator_assert_contains "$tmpdir/out" "label=hello world"
echo "OK"
