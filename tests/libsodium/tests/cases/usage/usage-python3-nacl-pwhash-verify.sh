#!/usr/bin/env bash
# @testcase: usage-python3-nacl-pwhash-verify
# @title: PyNaCl password hash verify
# @description: Exercises pynacl password hash verify through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-pwhash-verify"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.pwhash import argon2id
hashed = argon2id.str(b'password')
argon2id.verify(hashed, b'password')
print(hashed.decode().split('$')[1])
PY
