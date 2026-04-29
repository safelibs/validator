#!/usr/bin/env bash
# @testcase: usage-python3-yaml-scan-scalar-count
# @title: PyYAML scan scalar count
# @description: Exercises pyyaml scan scalar count through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-scan-scalar-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id"
import sys
import yaml
from yaml.events import MappingStartEvent, ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

tokens = list(yaml.scan('name: alpha\nvalue: beta\n'))
values = [token.value for token in tokens if isinstance(token, ScalarToken)]
assert values == ['name', 'alpha', 'value', 'beta']
print(len(values))
PY
