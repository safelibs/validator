#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r14-safe-load-large-int-arbitrary-precision
# @title: PyYAML safe_load preserves an integer larger than 2^64 with full precision
# @description: Loads a mapping whose value is the 22-digit literal 9999999999999999999999 and asserts safe_load returns a Python int with the exact value (more than 2^64), exercising PyYAML's arbitrary-precision integer support that delegates to Python's native bignum int type.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, bignum
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = yaml.safe_load("x: 9999999999999999999999\n")
v = data['x']
assert isinstance(v, int) and not isinstance(v, bool), (v, type(v))
assert v == 9999999999999999999999, v
# Sanity: this value cannot fit in a 64-bit unsigned slot.
assert v > 2 ** 64, v
PY
