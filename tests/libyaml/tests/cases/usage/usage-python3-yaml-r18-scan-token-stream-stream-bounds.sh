#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r18-scan-token-stream-stream-bounds
# @title: PyYAML yaml.scan emits StreamStartToken first and StreamEndToken last
# @description: Calls yaml.scan over a small mapping document and asserts the first token is a StreamStartToken and the last token is a StreamEndToken — pinning the token-stream boundary contract.
# @timeout: 60
# @tags: usage, python3-yaml, scan, tokens, r18
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
from yaml.tokens import StreamStartToken, StreamEndToken

tokens = list(yaml.scan('k: v\n'))
assert tokens, tokens
assert isinstance(tokens[0], StreamStartToken), type(tokens[0])
assert isinstance(tokens[-1], StreamEndToken), type(tokens[-1])
PY
