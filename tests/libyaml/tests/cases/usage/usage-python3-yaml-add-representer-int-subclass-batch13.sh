#!/usr/bin/env bash
# @testcase: usage-python3-yaml-add-representer-int-subclass-batch13
# @title: PyYAML add_representer for an int subclass
# @description: Registers a yaml.add_representer for an int subclass that emits the value as a plain integer scalar, verifying the dumper picks the custom representer instead of failing on the unknown subclass.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-add-representer-int-subclass-batch13"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

class MyInt(int):
    pass

def repr_myint(dumper, data):
    return dumper.represent_scalar("tag:yaml.org,2002:int", str(int(data)))

yaml.add_representer(MyInt, repr_myint)

data = {"answer": MyInt(42), "count": MyInt(7)}
text = yaml.dump(data, default_flow_style=False, sort_keys=True)

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

assert "!!python" not in text, text
assert "answer: 42" in text, text
assert "count: 7" in text, text

loaded = yaml.safe_load(text)
assert loaded == {"answer": 42, "count": 7}, loaded
assert isinstance(loaded["answer"], int)

print("ANSWER", loaded["answer"])
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "answer: 42"
validator_assert_contains "$tmpdir/out.yaml" "count: 7"
if grep -q "!!python" "$tmpdir/out.yaml"; then
  echo "unexpected python tag in output" >&2
  exit 1
fi
echo "OK"
