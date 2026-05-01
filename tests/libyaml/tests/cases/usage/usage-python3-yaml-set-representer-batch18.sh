#!/usr/bin/env bash
# @testcase: usage-python3-yaml-set-representer-batch18
# @title: PyYAML custom !myset representer round-trips a Python set via SafeDumper / SafeLoader
# @description: Registers a custom representer on a SafeDumper subclass that emits Python sets as a sorted YAML sequence under a "!myset" tag, plus a paired constructor on a SafeLoader subclass that rebuilds a Python set from the sequence. Verifies the dumped text contains the !myset tag and a deterministic sorted ordering, and that loading reproduces a set with the original membership.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-set-representer-batch18"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

class SetDumper(yaml.SafeDumper):
    pass

class SetLoader(yaml.SafeLoader):
    pass

MYSET_TAG = "!myset"

def represent_set(dumper, data):
    # Sort to produce deterministic output regardless of hash ordering.
    return dumper.represent_sequence(MYSET_TAG, sorted(data))

def construct_set(loader, node):
    return set(loader.construct_sequence(node))

SetDumper.add_representer(set, represent_set)
SetLoader.add_constructor(MYSET_TAG, construct_set)

original = {"colors": {"red", "green", "blue"}, "label": "palette"}

text = yaml.dump(original, Dumper=SetDumper, default_flow_style=False, sort_keys=True)

# Tagged sequence under the custom !myset tag.
assert "!myset" in text, text
# Sorted membership in the emitted sequence.
assert "- blue" in text, text
assert "- green" in text, text
assert "- red" in text, text

loaded = yaml.load(text, Loader=SetLoader)
assert isinstance(loaded["colors"], set), type(loaded["colors"])
assert loaded["colors"] == {"red", "green", "blue"}, loaded
assert loaded["label"] == "palette", loaded

# A plain SafeLoader without the !myset constructor refuses the tag.
try:
    yaml.safe_load(text)
except yaml.constructor.ConstructorError:
    pass
else:
    raise AssertionError("expected SafeLoader to reject unknown !myset tag")

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "!myset"
validator_assert_contains "$tmpdir/out.yaml" "- blue"
validator_assert_contains "$tmpdir/out.yaml" "- green"
validator_assert_contains "$tmpdir/out.yaml" "- red"
echo "OK"
