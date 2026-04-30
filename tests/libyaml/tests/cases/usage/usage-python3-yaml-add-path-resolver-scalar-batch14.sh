#!/usr/bin/env bash
# @testcase: usage-python3-yaml-add-path-resolver-scalar-batch14
# @title: PyYAML SafeLoader add_implicit_resolver custom scalar tag
# @description: Registers a regex-based implicit resolver on a SafeLoader subclass with a paired custom constructor, then verifies scalars whose plain form matches the pattern are wrapped with a custom Python type while non-matching scalars retain their default integer or string tags. The "path resolver" abstraction in PyYAML is exposed at scalar-resolution time via the same first_in tables, so this exercises the same machinery as add_path_resolver against a single scalar pattern.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-add-path-resolver-scalar-batch14"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import re
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

class PortLoader(yaml.SafeLoader):
    pass

# Match plain scalars of the form "port:NNNN" where NNNN is 1-5 digits.
PortLoader.add_implicit_resolver(
    "!port",
    re.compile(r"^port:[0-9]{1,5}$"),
    list("p"),
)

class Port:
    def __init__(self, raw):
        self.raw = raw
    def __repr__(self):
        return f"Port({self.raw!r})"
    def __eq__(self, other):
        return isinstance(other, Port) and other.raw == self.raw

def construct_port(loader, node):
    raw = loader.construct_scalar(node)
    return Port(raw.split(":", 1)[1])

PortLoader.add_constructor("!port", construct_port)

doc = (
    "service_a: port:8080\n"
    "service_b: port:9090\n"
    "label: example.org\n"
    "answer: 42\n"
)

data = yaml.load(doc, Loader=PortLoader)

# Plain scalars matching the pattern are wrapped with the custom type.
assert isinstance(data["service_a"], Port), data
assert data["service_a"] == Port("8080"), data
assert data["service_b"] == Port("9090"), data
# A non-matching string scalar stays a Python string.
assert data["label"] == "example.org", data
# A non-matching integer scalar still resolves to int.
assert data["answer"] == 42, data
assert isinstance(data["answer"], int), data

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(f"service_a={data['service_a']!r}\n")
    fh.write(f"label={data['label']!r}\n")
    fh.write(f"answer={data['answer']!r}\n")

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "service_a=Port('8080')"
validator_assert_contains "$tmpdir/out" "answer=42"
echo "OK"
