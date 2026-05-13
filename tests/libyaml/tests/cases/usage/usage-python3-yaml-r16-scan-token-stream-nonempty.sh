#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r16-scan-token-stream-nonempty
# @title: PyYAML scan yields a non-empty token stream framed by StreamStart and StreamEnd tokens
# @description: Feeds a small mapping document to yaml.scan and asserts the produced token list contains at least one Scalar token and is framed by a StreamStartToken at the start and StreamEndToken at the end — exercising the scanner public API.
# @timeout: 60
# @tags: usage, python3-yaml, scan, tokens
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "key: value\nother: 42\n"
tokens = list(yaml.scan(doc))
assert len(tokens) >= 4, tokens
class_names = [type(t).__name__ for t in tokens]
assert class_names[0] == 'StreamStartToken', class_names
assert class_names[-1] == 'StreamEndToken', class_names
assert any(n == 'ScalarToken' for n in class_names), class_names
PY
