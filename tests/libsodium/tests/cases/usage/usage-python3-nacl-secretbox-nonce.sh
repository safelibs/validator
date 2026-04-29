#!/usr/bin/env bash
# @testcase: usage-python3-nacl-secretbox-nonce
# @title: PyNaCl explicit nonce
# @description: Encrypts a message with PyNaCl SecretBox using an explicit nonce and decrypts it.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-secretbox-nonce"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.secret import SecretBox
key = b"1" * SecretBox.KEY_SIZE
nonce = b"2" * SecretBox.NONCE_SIZE
box = SecretBox(key)
cipher = box.encrypt(b"nonce payload", nonce)
assert box.decrypt(cipher) == b"nonce payload"
print("nonce payload")
PY
