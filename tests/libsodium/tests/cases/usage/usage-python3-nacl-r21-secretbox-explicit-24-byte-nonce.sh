#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r21-secretbox-explicit-24-byte-nonce
# @title: python3-nacl SecretBox nonce length constant equals 24 and encrypt requires 24-byte nonce
# @description: Asserts nacl.secret.SecretBox.NONCE_SIZE equals 24 and that encrypting with a freshly generated 24-byte nonce produces a ciphertext that decrypts back to the original plaintext via libsodium XSalsa20-Poly1305.
# @timeout: 60
# @tags: usage, sodium, secretbox, python, r21
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.secret
import nacl.utils

assert nacl.secret.SecretBox.NONCE_SIZE == 24, nacl.secret.SecretBox.NONCE_SIZE
assert nacl.secret.SecretBox.KEY_SIZE == 32, nacl.secret.SecretBox.KEY_SIZE

key = nacl.utils.random(nacl.secret.SecretBox.KEY_SIZE)
nonce = nacl.utils.random(nacl.secret.SecretBox.NONCE_SIZE)
assert len(nonce) == 24
box = nacl.secret.SecretBox(key)
pt = b"explicit nonce path"
ct = box.encrypt(pt, nonce)
# ct.nonce attribute is exactly the 24 bytes we supplied
assert ct.nonce == nonce
rt = box.decrypt(ct.ciphertext, ct.nonce)
assert rt == pt, rt
print("ok nonce_size=%d" % nacl.secret.SecretBox.NONCE_SIZE)
PY
