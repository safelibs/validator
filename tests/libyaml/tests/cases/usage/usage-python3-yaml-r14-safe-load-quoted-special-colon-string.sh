#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r14-safe-load-quoted-special-colon-string
# @title: PyYAML safe_dump quotes a string value containing a colon to keep it a string
# @description: Dumps a mapping whose value contains a colon-space sequence (which would be ambiguous as plain YAML) and asserts safe_dump emits the value with single quotes — preventing it from being parsed as a nested mapping — and that the round-tripped value is the original string.
# @timeout: 60
# @tags: usage, python3-yaml, safedump, quoting
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = {'a': 'hello: world'}
out = yaml.safe_dump(src)
# safe_dump must quote the value because plain-style would parse as a nested mapping.
assert "'hello: world'" in out or '"hello: world"' in out, out
back = yaml.safe_load(out)
assert back == src, (back, src)
assert isinstance(back['a'], str), type(back['a'])
PY
