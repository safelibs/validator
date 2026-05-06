#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r11-safe-load-bytes-input-utf8
# @title: PyYAML safe_load accepts a UTF-8 bytes object as input
# @description: Calls yaml.safe_load with a bytes (not str) source containing UTF-8 encoded ASCII, and asserts the parser decodes and returns the same dict produced from the equivalent str input — exercising the bytes-input branch of the loader stack.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, bytes
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
text = "name: alpha\nitems:\n  - 1\n  - 2\n"
data_text = yaml.safe_load(text)
data_bytes = yaml.safe_load(text.encode('utf-8'))
assert data_text == data_bytes, (data_text, data_bytes)
assert data_bytes == {'name': 'alpha', 'items': [1, 2]}, data_bytes
PY
