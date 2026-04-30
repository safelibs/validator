#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safedumper-add-representer-batch12
# @title: PyYAML SafeDumper add_representer
# @description: Registers a custom SafeDumper representer for a str subclass and verifies the emitted output uses the custom tag.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safedumper-add-representer-batch12"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

class Slug(str):
    pass

class MyDumper(yaml.SafeDumper):
    pass

def represent_slug(dumper, value):
    return dumper.represent_scalar("!slug", str(value))

MyDumper.add_representer(Slug, represent_slug)

text = yaml.dump({"id": Slug("hello-world")}, Dumper=MyDumper, default_flow_style=False)

assert "!slug" in text, text
assert "hello-world" in text, text

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("DUMP", text.strip())
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "!slug"
validator_assert_contains "$tmpdir/out.yaml" "hello-world"
echo "OK"
