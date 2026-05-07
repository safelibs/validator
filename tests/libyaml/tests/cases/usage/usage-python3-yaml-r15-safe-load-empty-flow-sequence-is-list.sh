#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r15-safe-load-empty-flow-sequence-is-list
# @title: PyYAML safe_load yields an empty Python list for an empty flow sequence []
# @description: Loads a YAML mapping value declared as the empty flow sequence "[]" and asserts safe_load returns a Python list with len 0 — locking in that the SafeLoader emits an empty list (not None or an empty dict) for the empty flow sequence form on Ubuntu 24.04 PyYAML 6.x.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, empty-flow
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "outer: []\n"
data = yaml.safe_load(doc)
inner = data['outer']
assert isinstance(inner, list), type(inner)
assert len(inner) == 0, inner
assert inner == [], inner
PY
