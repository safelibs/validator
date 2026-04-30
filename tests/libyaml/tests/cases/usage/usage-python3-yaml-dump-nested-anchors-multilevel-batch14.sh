#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-nested-anchors-multilevel-batch14
# @title: PyYAML dump nested anchors at multiple levels
# @description: Dumps a structure that shares both an inner mapping and an outer list across multiple keys, and verifies yaml.dump emits two distinct anchors with corresponding aliases.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-nested-anchors-multilevel-batch14"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import re
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

inner = {"k": "v"}
outer = [inner, "tail"]
data = {
    "first": {"nested": inner, "outer": outer},
    "second": {"nested": inner, "outer": outer},
}

text = yaml.dump(data, default_flow_style=False, sort_keys=True)
with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

anchors = set(re.findall(r"&(id\d+)", text))
aliases = set(re.findall(r"\*(id\d+)", text))

assert len(anchors) >= 2, (anchors, text)
assert anchors == aliases, (anchors, aliases, text)

loaded = yaml.safe_load(text)
assert loaded["first"]["nested"] == {"k": "v"}, loaded
assert loaded["second"]["outer"][0] == {"k": "v"}, loaded
assert loaded["first"]["nested"] is loaded["second"]["nested"], loaded
assert loaded["first"]["outer"] is loaded["second"]["outer"], loaded

print("ANCHORS", sorted(anchors))
print("OK")
PYCASE

grep -Eq '&id[0-9]+' "$tmpdir/out.yaml"
grep -Eq '\*id[0-9]+' "$tmpdir/out.yaml"
echo "OK"
