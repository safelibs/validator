#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r12-error-mark-line-column
# @title: PyYAML YAMLError on bad indent reports problem mark with line and column
# @description: Triggers a parse error with a deliberately mis-indented mapping value, catches the resulting YAMLError, and asserts the problem_mark exposes integer .line and .column attributes pointing into the broken document.
# @timeout: 60
# @tags: usage, python3-yaml, error
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

bad = "a: 1\n b: 2\nc:\n- 1\n - 2\n"
try:
    yaml.safe_load(bad)
except yaml.YAMLError as e:
    mark = getattr(e, 'problem_mark', None)
    assert mark is not None, 'expected problem_mark on YAMLError'
    assert isinstance(mark.line, int), type(mark.line)
    assert isinstance(mark.column, int), type(mark.column)
    assert mark.line >= 0, mark.line
    assert mark.column >= 0, mark.column
else:
    raise SystemExit('expected YAMLError on bad indent')
PY
