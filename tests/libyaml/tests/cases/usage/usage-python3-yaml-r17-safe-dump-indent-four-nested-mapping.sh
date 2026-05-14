#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r17-safe-dump-indent-four-nested-mapping
# @title: PyYAML safe_dump with indent=4 emits the nested key with four-space indentation
# @description: Dumps a nested mapping via yaml.safe_dump(default_flow_style=False, indent=4), captures the output, and asserts the inner key line is indented with exactly four leading spaces — locking in the indent option.
# @timeout: 60
# @tags: usage, python3-yaml, indent
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

text = yaml.safe_dump({'outer': {'inner': 'v'}}, default_flow_style=False, indent=4)
lines = text.splitlines()
# outer at col 0; inner at col 4.
outer = [l for l in lines if l.startswith('outer:')]
inner = [l for l in lines if l.startswith('    inner:')]
assert outer, text
assert inner, text
# Round-trip preserves value.
assert yaml.safe_load(text) == {'outer': {'inner': 'v'}}
PY
