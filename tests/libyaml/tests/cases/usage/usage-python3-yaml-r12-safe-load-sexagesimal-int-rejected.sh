#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r12-safe-load-sexagesimal-int-rejected
# @title: PyYAML safe_load resolves sexagesimal "1:30" to int 90
# @description: Loads the scalar 1:30 with safe_load and asserts the result is the YAML 1.1 sexagesimal integer 90, locking in PyYAML's continued YAML 1.1 sexagesimal resolution under the safe loader on noble. (Earlier rounds expected the 1.2-style string "1:30"; PyYAML 6.x in noble still emits 90.)
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, int
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

value = yaml.safe_load("v: 1:30\n")['v']
assert isinstance(value, int), type(value)
assert value == 90, value
PY
