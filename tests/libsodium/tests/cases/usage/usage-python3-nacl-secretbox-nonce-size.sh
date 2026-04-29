#!/usr/bin/env bash
# @testcase: usage-python3-nacl-secretbox-nonce-size
# @title: PyNaCl SecretBox nonce size
# @description: Encrypts data with PyNaCl SecretBox and verifies the generated nonce uses the expected libsodium size.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-secretbox-nonce-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.secret import SecretBox
key = b"3" * SecretBox.KEY_SIZE
box = SecretBox(key)
cipher = box.encrypt(b"nonce-size payload")
assert len(cipher.nonce) == SecretBox.NONCE_SIZE
assert box.decrypt(cipher) == b"nonce-size payload"
print(len(cipher.nonce))
PY
