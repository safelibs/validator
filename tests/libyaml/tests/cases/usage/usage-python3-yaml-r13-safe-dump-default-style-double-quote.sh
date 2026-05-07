#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r13-safe-dump-default-style-double-quote
# @title: PyYAML safe_dump default_style='"' wraps every string scalar in double quotes
# @description: Dumps a string-only mapping with default_style set to the double-quote indicator and asserts every key and value scalar in the output is surrounded by ASCII double quotes, then round-trips through safe_load to confirm the explicit quoting is reversible.
# @timeout: 60
# @tags: usage, python3-yaml, dump, scalar-style
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = {'name': 'alpha', 'colour': 'red', 'shape': 'square'}
out = yaml.safe_dump(src, default_style='"')
# Every scalar must be double-quoted in the output.
for token in ('"name"', '"alpha"', '"colour"', '"red"', '"shape"', '"square"'):
    assert token in out, (token, out)
# A bare unquoted scalar form must not appear at line start.
for line in out.splitlines():
    if not line:
        continue
    assert line.startswith('"'), line
back = yaml.safe_load(out)
assert back == src, (back, src)
PY
