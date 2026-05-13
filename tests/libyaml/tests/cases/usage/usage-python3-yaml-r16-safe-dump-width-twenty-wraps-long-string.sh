#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r16-safe-dump-width-twenty-wraps-long-string
# @title: PyYAML safe_dump width=20 produces multi-line output for a long flow mapping value
# @description: Dumps a mapping containing a long whitespace-separated string with width=20 and asserts the resulting document spans more than one line and contains no single output line longer than the configured width plus the canonical YAML continuation slack (a few characters).
# @timeout: 60
# @tags: usage, python3-yaml, safedump, width
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = {'msg': 'alpha bravo charlie delta echo foxtrot golf hotel india'}
text = yaml.safe_dump(src, width=20)
lines = text.rstrip('\n').splitlines()
assert len(lines) >= 2, ('expected multi-line output for width=20', text)
# Allow modest slack: PyYAML's width is a soft limit, but no line should be
# wildly longer than the configured width.
longest = max(len(l) for l in lines)
assert longest <= 40, ('width=20 produced an overlong line', longest, text)
PY
