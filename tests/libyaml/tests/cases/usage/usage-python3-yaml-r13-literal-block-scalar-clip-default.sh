#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r13-literal-block-scalar-clip-default
# @title: PyYAML safe_load preserves a literal block scalar with default clip chomping
# @description: Loads a literal block scalar written with the default clip-chomping indicator and asserts the value preserves embedded newlines verbatim while collapsing the trailing run of empty lines into a single final newline, distinguishing clip from strip and keep behaviour.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, block-scalar
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "text: |\n  alpha\n  beta\n  gamma\n\n\n"
data = yaml.safe_load(doc)
# Default ("clip") chomping keeps exactly one trailing newline regardless of
# how many blank lines followed the scalar.
assert data['text'] == 'alpha\nbeta\ngamma\n', repr(data['text'])
PY
