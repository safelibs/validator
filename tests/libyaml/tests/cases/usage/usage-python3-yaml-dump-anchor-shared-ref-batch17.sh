#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-anchor-shared-ref-batch17
# @title: PyYAML yaml.dump emits an anchor and alias for a shared list reference
# @description: Builds a Python mapping where two keys point at the exact same list object, dumps it with yaml.dump, and verifies a single anchor (&id001) and matching alias (*id001) are emitted so that reloading reproduces the shared reference under SafeLoader.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-anchor-shared-ref-batch17"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import re
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

shared = [10, 20, 30]
data = {"a": shared, "b": shared}
text = yaml.dump(data, default_flow_style=False, sort_keys=True)

# PyYAML detects the shared reference and emits an anchor + alias.
anchors = re.findall(r"&\S+", text)
aliases = re.findall(r"\*\S+", text)
assert len(anchors) == 1, (anchors, text)
assert len(aliases) == 1, (aliases, text)
# The alias name must reference the anchor name.
assert anchors[0][1:] == aliases[0][1:], (anchors, aliases)

# Round-trip preserves the shared identity.
loaded = yaml.safe_load(text)
assert loaded == {"a": [10, 20, 30], "b": [10, 20, 30]}, loaded
assert loaded["a"] is loaded["b"], "alias must restore shared identity"

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "&id001"
validator_assert_contains "$tmpdir/out.yaml" "*id001"
echo "OK"
