#!/usr/bin/env bash
# @testcase: usage-python3-yaml-scan-token-types
# @title: PyYAML scan token types
# @description: Scans YAML into low-level tokens with PyYAML and verifies the stream-start and scalar token classes are produced.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-scan-token-types"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
tokens = list(yaml.scan('key: value\n'))
names = [type(t).__name__ for t in tokens]
print('|'.join(names))
PYCASE
validator_assert_contains "$tmpdir/out" 'StreamStartToken'
validator_assert_contains "$tmpdir/out" 'ScalarToken'
