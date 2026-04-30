#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-load-all-three-docs-jq
# @title: PyYAML CSafeLoader load_all three documents jq verified
# @description: Streams three YAML documents through CSafeLoader.load_all, dumps them as JSON, and validates each document with jq.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/multi.yaml" <<'YAML'
---
doc: 1
name: alpha
---
doc: 2
name: beta
---
doc: 3
name: gamma
YAML

python3 - "$tmpdir/multi.yaml" "$tmpdir/multi.json" <<'PY'
import json
import sys
import yaml

src, dst = sys.argv[1], sys.argv[2]
loader = yaml.CSafeLoader
with open(src, "r", encoding="utf-8") as fh:
    docs = list(yaml.load_all(fh, Loader=loader))

assert len(docs) == 3, f"expected 3 docs, got {len(docs)}"
assert docs[0] == {"doc": 1, "name": "alpha"}
assert docs[1] == {"doc": 2, "name": "beta"}
assert docs[2] == {"doc": 3, "name": "gamma"}

with open(dst, "w", encoding="utf-8") as fh:
    json.dump(docs, fh)

print("LOADALL_OK", len(docs))
PY

jq -e 'length == 3' "$tmpdir/multi.json" >/dev/null
jq -e '.[0].doc == 1 and .[0].name == "alpha"' "$tmpdir/multi.json" >/dev/null
jq -e '.[1].doc == 2 and .[1].name == "beta"' "$tmpdir/multi.json" >/dev/null
jq -e '.[2].doc == 3 and .[2].name == "gamma"' "$tmpdir/multi.json" >/dev/null

echo "OK"
