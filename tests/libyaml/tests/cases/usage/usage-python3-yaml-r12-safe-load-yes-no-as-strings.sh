#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r12-safe-load-yes-no-as-strings
# @title: PyYAML safe_load treats YAML 1.1 "yes"/"no" as plain strings
# @description: Loads scalars yes and no with safe_load and asserts both come back as strings (not Python booleans), confirming that the YAML 1.1 boolean aliases were dropped from the SafeLoader's implicit bool resolver in PyYAML's YAML 1.2-leaning behavior.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, bool
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = yaml.safe_load("a: yes\nb: no\nc: true\nd: false\n")
assert data['a'] == 'yes' and isinstance(data['a'], str), data
assert data['b'] == 'no' and isinstance(data['b'], str), data
assert data['c'] is True, data
assert data['d'] is False, data
PY
