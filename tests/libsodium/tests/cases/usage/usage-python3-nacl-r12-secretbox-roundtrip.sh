#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r12-secretbox-roundtrip
# @title: PyNaCl SecretBox round-trips a payload under a fixed key and nonce
# @description: Encrypts a payload with nacl.secret.SecretBox using a deterministic 32-byte key and 24-byte nonce, asserts the ciphertext differs from plaintext, decrypts it back to the original, and verifies a flipped byte triggers nacl.exceptions.CryptoError on decrypt.
# @timeout: 120
# @tags: usage, crypto, secretbox, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.secret
import nacl.exceptions

key = bytes(range(32))
nonce = bytes([0x55]) * 24
plain = b"pynacl r12 secretbox payload"

box = nacl.secret.SecretBox(key)
ct = box.encrypt(plain, nonce)
assert bytes(ct) != plain
assert box.decrypt(bytes(ct)) == plain

tampered = bytearray(bytes(ct))
tampered[-1] ^= 0x01
try:
    box.decrypt(bytes(tampered))
except nacl.exceptions.CryptoError:
    pass
else:
    raise SystemExit("tampered SecretBox ciphertext was accepted")
print("ok", len(plain))
PY
