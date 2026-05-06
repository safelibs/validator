#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r9-load-all-multidoc
# @title: PyYAML safe_load_all parses multi-document stream
# @description: Concatenates three YAML documents separated by '---' and asserts safe_load_all yields three dictionaries in order.
# @timeout: 60
# @tags: usage, python3-yaml
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import yaml
stream = """---
n: 1
---
n: 2
---
n: 3
"""
docs = list(yaml.safe_load_all(stream))
assert len(docs) == 3, len(docs)
assert [d['n'] for d in docs] == [1, 2, 3]
PY
