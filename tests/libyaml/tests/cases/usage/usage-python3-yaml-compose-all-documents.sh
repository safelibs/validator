#!/usr/bin/env bash
# @testcase: usage-python3-yaml-compose-all-documents
# @title: PyYAML compose_all documents
# @description: Composes multiple YAML documents with compose_all and verifies both document roots are available in order.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-compose-all-documents"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
docs = list(yaml.compose_all('---\na: 1\n---\nb: 2\n'))
print(len(docs), docs[0].value[0][0].value, docs[1].value[0][0].value)
PYCASE
validator_assert_contains "$tmpdir/out" '2 a b'
