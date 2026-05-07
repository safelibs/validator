#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r13-folded-block-scalar-joins-with-space
# @title: PyYAML safe_load folded block scalar joins single line breaks with a single space
# @description: Loads a folded (>) block scalar with three contiguous content lines and asserts the loaded value collapses the line breaks between them into single ASCII spaces, terminating with one trailing newline under default clip chomping.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, folded-scalar
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "msg: >\n  alpha\n  beta\n  gamma\n"
data = yaml.safe_load(doc)
assert data['msg'] == 'alpha beta gamma\n', repr(data['msg'])
PY
