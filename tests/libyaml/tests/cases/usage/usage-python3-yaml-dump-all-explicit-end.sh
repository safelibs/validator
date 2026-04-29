#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-all-explicit-end
# @title: PyYAML dump all explicit end
# @description: Exercises pyyaml dump all explicit end through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-all-explicit-end"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id"
import sys
import yaml
from yaml.events import MappingStartEvent, ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

text = yaml.dump_all([{'a': 1}, {'b': 2}], explicit_end=True)
assert text.count('...') == 2
print(text.count('...'))
PY
