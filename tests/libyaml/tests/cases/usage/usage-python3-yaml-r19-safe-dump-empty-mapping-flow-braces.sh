#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r19-safe-dump-empty-mapping-flow-braces
# @title: PyYAML safe_dump renders an empty dict as the flow-style '{}' literal
# @description: Dumps an empty Python dict via yaml.safe_dump with default options and asserts the stripped output contains the literal '{}' marker — pinning the libyaml emitter's empty-mapping representation contract.
# @timeout: 60
# @tags: usage, python3-yaml, safe-dump, empty-mapping, r19
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

out = yaml.safe_dump({}).strip()
assert out == '{}', repr(out)
PY
