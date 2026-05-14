#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r17-scan-empty-input-empty-token-stream
# @title: PyYAML yaml.scan on empty input emits only the StreamStart/StreamEnd token pair
# @description: Feeds yaml.scan an empty string, materializes the token iterator into a list, and asserts the result is exactly the StreamStartToken/StreamEndToken pair (length 2) with no intermediate document content tokens.
# @timeout: 60
# @tags: usage, python3-yaml, scan, empty
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

tokens = list(yaml.scan(''))
kinds = [type(t).__name__ for t in tokens]
assert kinds == ['StreamStartToken', 'StreamEndToken'], kinds
PY
