#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r18-secretbox-easy-construct-roundtrip
# @title: PyNaCl SecretBox encrypt and decrypt round-trip a fixed payload with explicit nonce
# @description: Constructs a nacl.secret.SecretBox from a random 32-byte key, encrypts a fixed payload with an explicit 24-byte nonce, asserts the EncryptedMessage's ciphertext length equals plaintext+16 (Poly1305 tag) and that nonce attribute equals the supplied nonce, then decrypts using the SecretBox API and asserts the recovered plaintext equals the original byte-for-byte.
# @timeout: 60
# @tags: usage, crypto, secretbox, python, r18
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.secret
import nacl.utils

key = nacl.utils.random(nacl.secret.SecretBox.KEY_SIZE)
nonce = nacl.utils.random(nacl.secret.SecretBox.NONCE_SIZE)
box = nacl.secret.SecretBox(key)
msg = b"r18 pynacl secretbox payload xyz"

enc = box.encrypt(msg, nonce)
assert enc.nonce == nonce, ("nonce mismatch",)
assert len(enc.ciphertext) == len(msg) + 16, ("ct_len", len(enc.ciphertext))

pt = box.decrypt(enc)
assert pt == msg, ("plaintext mismatch", pt, msg)
print("ok secretbox len=%d" % len(enc.ciphertext))
PY
