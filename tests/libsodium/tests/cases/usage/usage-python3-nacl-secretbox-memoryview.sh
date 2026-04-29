#!/usr/bin/env bash
# @testcase: usage-python3-nacl-secretbox-memoryview
# @title: PyNaCl secretbox memoryview
# @description: Exercises pynacl secretbox memoryview through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-secretbox-memoryview"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.secret import SecretBox
key = b'4' * SecretBox.KEY_SIZE
box = SecretBox(key)
payload = memoryview(b'memory payload')
cipher = box.encrypt(payload)
assert box.decrypt(cipher) == b'memory payload'
print(len(cipher))
PY
