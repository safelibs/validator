#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r20-safe-dump-multiline-string-double-quoted
# @title: PyYAML safe_dump default_style='\"' wraps a scalar in double quotes
# @description: Dumps {'k': 'hello'} via yaml.safe_dump with default_style='"' and asserts the output contains the substring '"hello"' (the double-quoted form of the scalar), pinning the libyaml emitter style override.
# @timeout: 60
# @tags: usage, python3-yaml, safe-dump, default-style, double-quoted, r20
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

out = yaml.safe_dump({'k': 'hello'}, default_style='"')
assert '"hello"' in out, repr(out)
# Round-trip integrity.
back = yaml.safe_load(out)
assert back == {'k': 'hello'}, back
PY
