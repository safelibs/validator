#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r11-safe-load-complex-key-unhashable-error
# @title: PyYAML safe_load raises ConstructorError on unhashable complex mapping key
# @description: Loads a document using YAML 1.1 explicit complex-key syntax with a flow sequence as the key and asserts safe_load raises ConstructorError with the "found unhashable key" diagnostic — the well-defined behavior for keys that cannot be Python dict keys.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, error
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "? [a, b]\n: value\n"
try:
    yaml.safe_load(doc)
except yaml.constructor.ConstructorError as exc:
    msg = str(exc)
    assert 'found unhashable key' in msg, msg
    assert 'while constructing a mapping' in msg, msg
else:
    raise SystemExit('safe_load accepted unhashable complex key')
PY
