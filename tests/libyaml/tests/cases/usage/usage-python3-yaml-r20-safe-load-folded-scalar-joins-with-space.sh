#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r20-safe-load-folded-scalar-joins-with-space
# @title: PyYAML safe_load on a '>' folded block scalar joins consecutive lines with a single space
# @description: Parses 'k: >\n  hello\n  world\n' via yaml.safe_load and asserts the resulting string equals 'hello world\n' — pinning libyaml's folded-scalar line-joining contract.
# @timeout: 60
# @tags: usage, python3-yaml, safe-load, folded-scalar, r20
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = 'k: >\n  hello\n  world\n'
data = yaml.safe_load(doc)
v = data['k']
assert isinstance(v, str), (v, type(v))
assert v == 'hello world\n', repr(v)
PY
