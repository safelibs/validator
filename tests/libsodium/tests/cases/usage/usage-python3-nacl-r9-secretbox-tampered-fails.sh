#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r9-secretbox-tampered-fails
# @title: PyNaCl SecretBox rejects tampered ciphertext
# @description: Encrypts with PyNaCl SecretBox, mutates a single byte of the ciphertext, and verifies decryption raises CryptoError.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import nacl.secret
import nacl.utils
import nacl.exceptions

key = nacl.utils.random(nacl.secret.SecretBox.KEY_SIZE)
box = nacl.secret.SecretBox(key)
ct = box.encrypt(b"hello validator")
# Flip a byte in the ciphertext portion (after the nonce prefix).
nonce_len = nacl.secret.SecretBox.NONCE_SIZE
mutable = bytearray(ct)
mutable[nonce_len] ^= 0x01
tampered = bytes(mutable)

try:
    box.decrypt(tampered)
except nacl.exceptions.CryptoError:
    pass
else:
    raise SystemExit("tampered ciphertext was accepted")

# Sanity: original still decrypts.
assert box.decrypt(ct) == b"hello validator"
PY
