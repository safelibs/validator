#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-all-explicit-start
# @title: PyYAML dump_all explicit start
# @description: Dumps multiple YAML documents with explicit document starts and verifies both start markers are emitted.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-all-explicit-start"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import yaml
from yaml.events import AliasEvent, MappingStartEvent, ScalarEvent
from yaml.tokens import AliasToken, AnchorToken, ScalarToken

case_id = sys.argv[1]
tmpdir = sys.argv[2]

docs = [{"name": "alpha"}, {"name": "beta"}]
text = yaml.dump_all(docs, explicit_start=True, sort_keys=False)
assert text.startswith("---")
assert text.count("---") == 2
assert list(yaml.safe_load_all(text)) == docs
print(text.count("---"))
PY
