#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r19-secretbox-ciphertext-overhead-40
# @title: PyNaCl SecretBox EncryptedMessage total length is plaintext + 40 bytes (24 nonce + 16 tag)
# @description: Encrypts a fixed payload with nacl.secret.SecretBox using an auto-generated nonce, asserts len(EncryptedMessage) == len(plaintext) + 40 (24-byte nonce prefix + 16-byte Poly1305 tag), asserts the ciphertext attribute alone is len(plaintext) + 16, and decrypts via SecretBox(key).decrypt(enc) asserting the recovered plaintext equals the original byte-for-byte.
# @timeout: 60
# @tags: usage, crypto, secretbox, python, r19
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.secret
import nacl.utils

key = nacl.utils.random(nacl.secret.SecretBox.KEY_SIZE)
box = nacl.secret.SecretBox(key)
msg = b"r19 pynacl secretbox overhead payload"

enc = box.encrypt(msg)
assert len(enc) == len(msg) + 40, ("enc_len", len(enc), len(msg))
assert len(enc.ciphertext) == len(msg) + 16, ("ct_len", len(enc.ciphertext))
assert len(enc.nonce) == 24, ("nonce_len", len(enc.nonce))

pt = box.decrypt(enc)
assert pt == msg, ("pt", pt, msg)
print("ok overhead enc=%d ct=%d" % (len(enc), len(enc.ciphertext)))
PY
