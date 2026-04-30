#!/usr/bin/env bash
# @testcase: usage-python3-yaml-add-constructor-str-subclass-batch12
# @title: PyYAML add_constructor str subclass
# @description: Registers a custom !slug constructor on a SafeLoader subclass and confirms loaded values are instances of the str subclass.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-add-constructor-str-subclass-batch12"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" >"$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]

class Slug(str):
    pass

class SlugLoader(yaml.SafeLoader):
    pass

def construct_slug(loader, node):
    return Slug(loader.construct_scalar(node))

SlugLoader.add_constructor("!slug", construct_slug)

source = "id: !slug 'hello-world'\nplain: just-a-string\n"
data = yaml.load(source, Loader=SlugLoader)

assert isinstance(data["id"], Slug), type(data["id"])
assert isinstance(data["id"], str)
assert data["id"] == "hello-world"
assert not isinstance(data["plain"], Slug)
assert data["plain"] == "just-a-string"

print("ID_TYPE", type(data["id"]).__name__)
print("ID_VAL", data["id"])
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "ID_TYPE Slug"
validator_assert_contains "$tmpdir/out" "ID_VAL hello-world"
validator_assert_contains "$tmpdir/out" "OK"
echo "OK"
