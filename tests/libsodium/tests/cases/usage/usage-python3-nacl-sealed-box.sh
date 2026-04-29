#!/usr/bin/env bash
# @testcase: usage-python3-nacl-sealed-box
# @title: PyNaCl sealed box
# @description: Encrypts and decrypts a message with PyNaCl SealedBox.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-sealed-box"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.public import PrivateKey, SealedBox
recipient = PrivateKey.generate()
sealed = SealedBox(recipient.public_key).encrypt(b"sealed payload")
plain = SealedBox(recipient).decrypt(sealed)
assert plain == b"sealed payload"
print(plain.decode())
PY
