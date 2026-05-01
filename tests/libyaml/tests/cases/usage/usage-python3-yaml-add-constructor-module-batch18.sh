#!/usr/bin/env bash
# @testcase: usage-python3-yaml-add-constructor-module-batch18
# @title: PyYAML yaml.add_constructor module-level API binds a tag on a Loader subclass
# @description: Uses the module-level yaml.add_constructor function (rather than calling Loader.add_constructor as a classmethod) with an explicit Loader= argument to register a "!point" constructor that builds a (x, y) tuple from a "x,y" scalar. Verifies the registration is scoped to the supplied loader subclass and that the parent SafeLoader still rejects the unknown !point tag.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-add-constructor-module-batch18"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

class PointLoader(yaml.SafeLoader):
    pass

POINT_TAG = "!point"

def construct_point(loader, node):
    raw = loader.construct_scalar(node)
    x_str, y_str = raw.split(",", 1)
    return (int(x_str), int(y_str))

# Module-level API with explicit Loader= keyword: equivalent to
# PointLoader.add_constructor(POINT_TAG, construct_point) but exercises the
# module function dispatcher.
yaml.add_constructor(POINT_TAG, construct_point, Loader=PointLoader)

doc = (
    "origin: !point 0,0\n"
    "corner: !point 10,20\n"
    "label: middle\n"
)

data = yaml.load(doc, Loader=PointLoader)
assert data["origin"] == (0, 0), data
assert data["corner"] == (10, 20), data
assert isinstance(data["origin"], tuple), type(data["origin"])
assert data["label"] == "middle", data

# The registration is scoped to PointLoader. The base SafeLoader must reject
# the unknown !point tag.
try:
    yaml.safe_load(doc)
except yaml.constructor.ConstructorError:
    pass
else:
    raise AssertionError("expected SafeLoader to reject unknown !point tag")

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(f"origin={data['origin']}\n")
    fh.write(f"corner={data['corner']}\n")
    fh.write(f"label={data['label']}\n")

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "origin=(0, 0)"
validator_assert_contains "$tmpdir/out" "corner=(10, 20)"
validator_assert_contains "$tmpdir/out" "label=middle"
echo "OK"
