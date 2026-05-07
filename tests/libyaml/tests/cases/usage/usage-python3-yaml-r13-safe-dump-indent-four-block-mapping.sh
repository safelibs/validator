#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r13-safe-dump-indent-four-block-mapping
# @title: PyYAML safe_dump indent=4 produces four-space indentation in block output
# @description: Dumps a nested mapping with indent=4 and default_flow_style=False and asserts the resulting block output indents nested keys by exactly four ASCII spaces, distinguishing the indent=4 setting from the default two-space block indentation.
# @timeout: 60
# @tags: usage, python3-yaml, dump, indent
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = {'outer': {'inner': 1, 'other': 2}}
out = yaml.safe_dump(src, indent=4, default_flow_style=False)
# Nested keys must be indented by 4 spaces under "outer:".
assert 'outer:\n    inner: 1\n' in out, out
assert '    other: 2\n' in out, out
# A two-space-indented form must not appear.
assert '\n  inner:' not in out, out
back = yaml.safe_load(out)
assert back == src, (back, src)
PY
