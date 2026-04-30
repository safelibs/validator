#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-aliases-cycle-batch13
# @title: PyYAML dump emits anchor and alias for shared object
# @description: Dumps a structure that reuses the same list object twice and verifies yaml.dump emits an anchor (&) on the first occurrence and an alias (*) on the second.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-aliases-cycle-batch13"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import re
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

shared = ["x", "y", "z"]
data = {"first": shared, "second": shared}
text = yaml.dump(data, default_flow_style=False, sort_keys=True)

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

assert re.search(r"&id\d+", text), text
assert re.search(r"\*id\d+", text), text

# Verify safe_load roundtrips the alias to the same list contents
loaded = yaml.safe_load(text)
assert loaded["first"] == ["x", "y", "z"]
assert loaded["second"] == ["x", "y", "z"]

print("HAS_ANCHOR", bool(re.search(r"&id\d+", text)))
print("HAS_ALIAS", bool(re.search(r"\*id\d+", text)))
print("OK")
PYCASE

grep -Eq '&id[0-9]+' "$tmpdir/out.yaml"
grep -Eq '\*id[0-9]+' "$tmpdir/out.yaml"
echo "OK"
