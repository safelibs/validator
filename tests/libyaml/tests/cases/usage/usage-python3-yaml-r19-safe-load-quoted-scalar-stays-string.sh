#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r19-safe-load-quoted-scalar-stays-string
# @title: PyYAML safe_load preserves quoted integer-looking scalars as strings
# @description: Loads a document where a value '"42"' is double-quoted, asserts the resulting Python value is the string '42' rather than the integer 42 — pinning the libyaml quoted-scalar tag resolution path.
# @timeout: 60
# @tags: usage, python3-yaml, quoted-scalar, r19
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = yaml.safe_load('val: "42"\n')
v = data['val']
assert isinstance(v, str), type(v)
assert v == '42', v
PY
