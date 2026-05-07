#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r15-safe-load-empty-flow-mapping-is-dict
# @title: PyYAML safe_load yields an empty Python dict for an empty flow mapping {}
# @description: Loads a YAML mapping value declared as the empty flow mapping "{}" and asserts safe_load returns a Python dict with len 0 — locking in that the SafeLoader emits an empty dict (not None or an empty list) for the empty flow mapping form on Ubuntu 24.04 PyYAML 6.x. Distinct from the empty document test which exercises a missing root.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, empty-flow
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "outer: {}\n"
data = yaml.safe_load(doc)
inner = data['outer']
assert isinstance(inner, dict), type(inner)
assert len(inner) == 0, inner
assert inner == {}, inner
PY
