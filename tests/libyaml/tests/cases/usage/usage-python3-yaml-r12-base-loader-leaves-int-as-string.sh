#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r12-base-loader-leaves-int-as-string
# @title: PyYAML BaseLoader returns "42" as a string, not int
# @description: Loads the scalar 42 with the BaseLoader and asserts the result is the string "42" with no implicit type resolution, distinguishing it from SafeLoader which would coerce to Python int.
# @timeout: 60
# @tags: usage, python3-yaml, baseloader
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

base = yaml.load("x: 42\n", Loader=yaml.BaseLoader)
safe = yaml.safe_load("x: 42\n")
assert isinstance(base['x'], str) and base['x'] == '42', base
assert isinstance(safe['x'], int) and safe['x'] == 42, safe
PY
