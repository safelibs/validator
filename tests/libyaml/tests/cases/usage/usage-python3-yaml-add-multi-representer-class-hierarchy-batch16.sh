#!/usr/bin/env bash
# @testcase: usage-python3-yaml-add-multi-representer-class-hierarchy-batch16
# @title: PyYAML SafeDumper.add_multi_representer covers a class hierarchy
# @description: Subclasses yaml.SafeDumper, registers add_multi_representer on a base class, and dumps instances of two subclasses verifying both subclass instances are serialized through the inherited representer to the expected scalar form.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-add-multi-representer-class-hierarchy-batch16"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

class Animal:
    def __init__(self, name):
        self.name = name

class Dog(Animal):
    pass

class Wolf(Dog):
    pass

class HierarchyDumper(yaml.SafeDumper):
    pass

def represent_animal(dumper, instance):
    payload = f"{type(instance).__name__}:{instance.name}"
    return dumper.represent_scalar("tag:yaml.org,2002:str", payload)

# add_multi_representer routes every Animal subclass through represent_animal.
HierarchyDumper.add_multi_representer(Animal, represent_animal)

data = [Dog("rex"), Wolf("akela")]
text = yaml.dump(data, Dumper=HierarchyDumper, default_flow_style=False)

assert "Dog:rex" in text, text
assert "Wolf:akela" in text, text

# safe_load reads the values back as plain strings.
loaded = yaml.safe_load(text)
assert loaded == ["Dog:rex", "Wolf:akela"], loaded

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "Dog:rex"
validator_assert_contains "$tmpdir/out.yaml" "Wolf:akela"
echo "OK"
