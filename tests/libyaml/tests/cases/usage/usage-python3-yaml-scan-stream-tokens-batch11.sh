#!/usr/bin/env bash
# @testcase: usage-python3-yaml-scan-stream-tokens-batch11
# @title: PyYAML scan stream tokens
# @description: Scans YAML tokens and checks stream start and end tokens.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-scan-stream-tokens-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id"
import re
import sys
import yaml

case_id = sys.argv[1]

tokens = list(yaml.scan('a: 1\n'))
names = [type(token).__name__ for token in tokens]
assert 'StreamStartToken' in names and 'StreamEndToken' in names
print(','.join(names))
PYCASE
