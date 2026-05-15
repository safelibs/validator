#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r19-safe-load-null-key-as-none
# @title: PyYAML safe_load resolves a bare ~ mapping key into Python None
# @description: Parses a YAML mapping whose key is the tilde '~' null shorthand, then asserts the resulting Python dict has None as a key bound to the expected value — pinning the libyaml null-key resolution path.
# @timeout: 60
# @tags: usage, python3-yaml, null-key, r19
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "~: nothing-here\n"
data = yaml.safe_load(doc)
assert isinstance(data, dict), type(data)
assert None in data, list(data.keys())
assert data[None] == 'nothing-here', data
PY
