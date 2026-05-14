#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r17-safe-dump-explicit-start-emits-triple-dash
# @title: PyYAML safe_dump with explicit_start=True emits a leading '---' document marker
# @description: Dumps a simple mapping via yaml.safe_dump(explicit_start=True), captures the output, and asserts the first line is exactly '---' followed by the mapping body, exercising the explicit-start option of the emitter.
# @timeout: 60
# @tags: usage, python3-yaml, explicit-start
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

text = yaml.safe_dump({'k': 'v'}, explicit_start=True)
lines = text.splitlines()
assert lines, text
assert lines[0] == '---', (lines, text)
# Body line follows.
assert any(l.strip().startswith('k:') for l in lines[1:]), text
PY
