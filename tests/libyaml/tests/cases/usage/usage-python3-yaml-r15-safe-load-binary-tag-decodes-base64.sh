#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r15-safe-load-binary-tag-decodes-base64
# @title: PyYAML safe_load !!binary scalar decodes base64 payload to Python bytes
# @description: Loads a YAML mapping value with an explicit !!binary tag and a base64-encoded scalar, and asserts safe_load returns Python bytes equal to the decoded payload — locking in the SafeConstructor !!binary handler on Ubuntu 24.04 PyYAML 6.x.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, binary-tag
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

# base64 of b'abc' is 'YWJj'
doc = "payload: !!binary YWJj\n"
data = yaml.safe_load(doc)
v = data['payload']
assert isinstance(v, bytes), type(v)
assert v == b'abc', v
PY
