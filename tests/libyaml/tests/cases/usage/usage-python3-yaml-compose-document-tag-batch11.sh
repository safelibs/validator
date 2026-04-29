#!/usr/bin/env bash
# @testcase: usage-python3-yaml-compose-document-tag-batch11
# @title: PyYAML compose document tag
# @description: Composes a YAML document and inspects the root node tag.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-compose-document-tag-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id"
import re
import sys
import yaml

case_id = sys.argv[1]

node = yaml.compose('value: 7')
assert node.tag.endswith(':map')
print(node.tag)
PYCASE
