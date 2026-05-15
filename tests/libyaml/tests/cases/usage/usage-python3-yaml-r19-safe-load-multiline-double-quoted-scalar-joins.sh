#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r19-safe-load-multiline-double-quoted-scalar-joins
# @title: PyYAML safe_load joins a double-quoted scalar split across two lines with a single space
# @description: Loads a YAML document containing a double-quoted scalar broken across two lines, asserts the resulting Python string is the two halves concatenated with exactly one space — pinning libyaml's double-quoted line-folding contract.
# @timeout: 60
# @tags: usage, python3-yaml, double-quoted, line-fold, r19
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = 'msg: "hello\n  world"\n'
data = yaml.safe_load(doc)
assert data == {'msg': 'hello world'}, data
PY
