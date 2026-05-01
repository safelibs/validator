#!/usr/bin/env bash
# @testcase: usage-python3-yaml-add-multi-constructor-batch18
# @title: PyYAML yaml.add_multi_constructor dispatches all tags sharing a prefix
# @description: Registers a single multi-constructor for the "!ext:" tag prefix on a SafeLoader subclass so that any tagged scalar whose tag starts with !ext: is routed through one handler that receives the tag suffix. Verifies that two distinct suffixes (!ext:int and !ext:rev) are both dispatched to the same constructor and produce different result objects derived from the suffix.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-add-multi-constructor-batch18"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

class ExtLoader(yaml.SafeLoader):
    pass

calls = []

def multi_handler(loader, tag_suffix, node):
    raw = loader.construct_scalar(node)
    calls.append(tag_suffix)
    if tag_suffix == "int":
        return int(raw)
    if tag_suffix == "rev":
        return raw[::-1]
    return ("unknown", tag_suffix, raw)

yaml.add_multi_constructor("!ext:", multi_handler, Loader=ExtLoader)

doc = (
    "n: !ext:int 42\n"
    "s: !ext:rev hello\n"
    "label: plain\n"
)

data = yaml.load(doc, Loader=ExtLoader)

assert data["n"] == 42, data
assert isinstance(data["n"], int), type(data["n"])
assert data["s"] == "olleh", data
assert data["label"] == "plain", data

# Both suffixes were dispatched through the same multi-constructor.
assert sorted(calls) == ["int", "rev"], calls

# SafeLoader (no multi-constructor registered) refuses the prefix.
try:
    yaml.safe_load(doc)
except yaml.constructor.ConstructorError:
    pass
else:
    raise AssertionError("expected SafeLoader to reject !ext: prefix")

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(f"n={data['n']}\n")
    fh.write(f"s={data['s']}\n")
    fh.write(f"label={data['label']}\n")
    fh.write("calls=" + ",".join(sorted(calls)) + "\n")

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "n=42"
validator_assert_contains "$tmpdir/out" "s=olleh"
validator_assert_contains "$tmpdir/out" "calls=int,rev"
echo "OK"
