#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r12-safe-load-yes-no-as-strings
# @title: PyYAML safe_load resolves YAML 1.1 "yes"/"no" to Python booleans
# @description: Loads scalars yes/no/true/false with safe_load and asserts that yes/no map to True/False alongside the spec-true true/false aliases, locking in PyYAML's continued YAML 1.1 boolean resolver on noble. (Earlier rounds expected yes/no to drop to plain strings under YAML 1.2 semantics; PyYAML 6.x still resolves them.)
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, bool
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = yaml.safe_load("a: yes\nb: no\nc: true\nd: false\n")
assert data['a'] is True, data
assert data['b'] is False, data
assert data['c'] is True, data
assert data['d'] is False, data
PY
