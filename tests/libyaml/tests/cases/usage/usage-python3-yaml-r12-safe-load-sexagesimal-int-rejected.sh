#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r12-safe-load-sexagesimal-int-rejected
# @title: PyYAML safe_load treats sexagesimal "1:30" as a string, not 90
# @description: Loads the scalar 1:30 with safe_load and asserts the result is the literal string "1:30" rather than the YAML 1.1 sexagesimal integer 90, locking in PyYAML's drop of YAML 1.1 sexagesimal resolution under the safe loader.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, int
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

value = yaml.safe_load("v: 1:30\n")['v']
assert isinstance(value, str), type(value)
assert value == '1:30', value
PY
