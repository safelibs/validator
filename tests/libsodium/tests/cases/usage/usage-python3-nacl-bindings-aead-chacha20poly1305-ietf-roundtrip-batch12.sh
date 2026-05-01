#!/usr/bin/env bash
# @testcase: usage-python3-nacl-bindings-aead-chacha20poly1305-ietf-roundtrip-batch12
# @title: PyNaCl ChaCha20-Poly1305-IETF AEAD round-trip
# @description: Encrypts a fixed payload with a 32-byte key, 12-byte IETF nonce, and AAD via nacl.bindings.crypto_aead_chacha20poly1305_ietf_encrypt, asserts the ciphertext length is plaintext + ABYTES, decrypts back to the original, and confirms a wrong AAD raises a verification error.
# @timeout: 120
# @tags: usage, crypto, aead, chacha, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.bindings as nb

key = bytes([0x33]) * nb.crypto_aead_chacha20poly1305_ietf_KEYBYTES
nonce = bytes([0x77]) * nb.crypto_aead_chacha20poly1305_ietf_NPUBBYTES
aad = b"validator-aad"
plain = b"chacha20-poly1305-ietf aead payload"

ct = nb.crypto_aead_chacha20poly1305_ietf_encrypt(plain, aad, nonce, key)
assert len(ct) == len(plain) + nb.crypto_aead_chacha20poly1305_ietf_ABYTES, len(ct)

pt = nb.crypto_aead_chacha20poly1305_ietf_decrypt(ct, aad, nonce, key)
assert pt == plain, pt

# Wrong AAD must raise.
try:
    nb.crypto_aead_chacha20poly1305_ietf_decrypt(ct, b"wrong-aad", nonce, key)
except Exception:
    pass
else:
    raise SystemExit("decrypt under wrong AAD did not fail")

# Tampered ciphertext must also raise.
tampered = bytearray(ct)
tampered[0] ^= 0x01
try:
    nb.crypto_aead_chacha20poly1305_ietf_decrypt(bytes(tampered), aad, nonce, key)
except Exception:
    pass
else:
    raise SystemExit("decrypt under tampered ciphertext did not fail")

print("ok", len(ct))
PY
