#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r14-safe-load-hex-uppercase
# @title: PyYAML safe_load resolves uppercase 0xFF hex literal to decimal int 255
# @description: Loads a mapping whose value is the YAML 1.1 hexadecimal literal 0xFF (uppercase digits) and asserts safe_load returns Python int 255, exercising the implicit int resolver's uppercase-hex regex branch — distinct from existing lowercase 0xff coverage.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, hex
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = yaml.safe_load("x: 0xFF\n")
v = data['x']
assert isinstance(v, int) and not isinstance(v, bool), (v, type(v))
assert v == 255, v
# Lowercase form must also resolve to the same value.
assert yaml.safe_load("x: 0xff\n")['x'] == 255
# Mixed case still hex.
assert yaml.safe_load("x: 0xAb\n")['x'] == 0xab
PY
