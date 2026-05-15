#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r20-safe-load-negative-int-keeps-sign
# @title: PyYAML safe_load on '-42' yields the Python int -42
# @description: Parses the document 'n: -42' via yaml.safe_load and asserts the resulting value is the int -42, exactly preserving sign and type — pinning the libyaml-driven negative-integer resolver.
# @timeout: 60
# @tags: usage, python3-yaml, safe-load, negative-int, r20
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = yaml.safe_load('n: -42\n')
v = data['n']
assert isinstance(v, int) and not isinstance(v, bool), (v, type(v))
assert v == -42, v
PY
