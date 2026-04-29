#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-all-three-docs
# @title: PyYAML safe load all three docs
# @description: Loads a stream of three YAML documents with safe_load_all and verifies each document scalar appears in stream order.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-all-three-docs"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
docs = list(yaml.safe_load_all('---\n1\n---\n2\n---\n3\n'))
print(','.join(str(d) for d in docs))
PYCASE
validator_assert_contains "$tmpdir/out" '1,2,3'
