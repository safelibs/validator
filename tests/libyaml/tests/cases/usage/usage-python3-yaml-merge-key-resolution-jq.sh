#!/usr/bin/env bash
# @testcase: usage-python3-yaml-merge-key-resolution-jq
# @title: PyYAML merge key resolution via CSafeLoader with jq verification
# @description: Resolves a YAML merge key with CSafeLoader, dumps the result as JSON, and uses jq to confirm inherited fields and overrides.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/merge.yaml" <<'YAML'
defaults: &base
  name: alpha
  count: 2
  enabled: true
item:
  <<: *base
  count: 3
  extra: gamma
YAML

python3 - "$tmpdir/merge.yaml" "$tmpdir/merge.json" <<'PY'
import json
import sys
import yaml

src, dst = sys.argv[1], sys.argv[2]
with open(src, "r", encoding="utf-8") as fh:
    data = yaml.load(fh, Loader=yaml.CSafeLoader)

item = data["item"]
# Inherited from base
assert item["name"] == "alpha", item
assert item["enabled"] is True, item
# Overridden value
assert item["count"] == 3, item
# Locally defined
assert item["extra"] == "gamma", item

with open(dst, "w", encoding="utf-8") as fh:
    json.dump(data, fh)

print("MERGE_OK")
PY

jq -e '.item.name == "alpha"' "$tmpdir/merge.json" >/dev/null
jq -e '.item.count == 3' "$tmpdir/merge.json" >/dev/null
jq -e '.item.enabled == true' "$tmpdir/merge.json" >/dev/null
jq -e '.item.extra == "gamma"' "$tmpdir/merge.json" >/dev/null
echo "OK"
