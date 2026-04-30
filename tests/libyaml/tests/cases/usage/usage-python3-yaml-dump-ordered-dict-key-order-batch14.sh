#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-ordered-dict-key-order-batch14
# @title: PyYAML dump preserves OrderedDict insertion order
# @description: Registers a representer for collections.OrderedDict on yaml.SafeDumper and verifies yaml.safe_dump emits keys in insertion order rather than alphabetically when sort_keys=False.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-ordered-dict-key-order-batch14"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import collections
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

def represent_ordered(dumper, data):
    return dumper.represent_mapping("tag:yaml.org,2002:map", data.items())

yaml.SafeDumper.add_representer(collections.OrderedDict, represent_ordered)

od = collections.OrderedDict()
od["zeta"] = 1
od["alpha"] = 2
od["mu"] = 3

text = yaml.safe_dump(od, default_flow_style=False, sort_keys=False)
with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

lines = [line.split(":", 1)[0] for line in text.strip().splitlines()]
assert lines == ["zeta", "alpha", "mu"], (lines, text)

# Round-trip and verify the dict order survives in 3.7+ regular dicts.
loaded = yaml.safe_load(text)
assert list(loaded.keys()) == ["zeta", "alpha", "mu"], loaded

print("ORDER", lines)
print("OK")
PYCASE

# zeta must appear before alpha in the file even though alpha < zeta lexicographically.
python3 - <<'PYCHECK' "$tmpdir/out.yaml"
import sys
text = open(sys.argv[1]).read()
assert text.index("zeta") < text.index("alpha") < text.index("mu"), text
print("ORDER_OK")
PYCHECK

echo "OK"
