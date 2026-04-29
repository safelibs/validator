#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-dump-indent
# @title: PyYAML safe dump indent
# @description: Exercises pyyaml safe dump indent through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-dump-indent"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id"
import sys
import yaml
from yaml.events import MappingStartEvent, ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

text = yaml.safe_dump({'root': {'child': 'alpha'}}, indent=4)
assert '    child' in text
print(text.splitlines()[1])
PY
