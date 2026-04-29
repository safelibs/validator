#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-dump-allow-unicode
# @title: PyYAML safe dump allow unicode
# @description: Dumps a mapping with allow_unicode enabled in PyYAML and verifies the expected scalar text is emitted.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-dump-allow-unicode"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
print(yaml.safe_dump({'word': 'cafe'}, allow_unicode=True), end='')
PYCASE
validator_assert_contains "$tmpdir/out" 'word: cafe'
