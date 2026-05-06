#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r11-aead-xchacha20poly1305-roundtrip
# @title: PyNaCl AEAD XChaCha20-Poly1305 IETF roundtrip with associated data
# @description: Encrypts a payload with nacl.bindings.crypto_aead_xchacha20poly1305_ietf_encrypt under a 32-byte key, 24-byte nonce, and explicit associated data, then decrypts the ciphertext back to the original plaintext and asserts that flipping a single byte of the ciphertext produces a CryptoError on decrypt.
# @timeout: 180
# @tags: usage, crypto, python, aead
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
from nacl.bindings import (
    crypto_aead_xchacha20poly1305_ietf_encrypt,
    crypto_aead_xchacha20poly1305_ietf_decrypt,
    crypto_aead_xchacha20poly1305_ietf_KEYBYTES,
    crypto_aead_xchacha20poly1305_ietf_NPUBBYTES,
)
from nacl.exceptions import CryptoError

key = bytes(range(crypto_aead_xchacha20poly1305_ietf_KEYBYTES))
nonce = bytes(range(crypto_aead_xchacha20poly1305_ietf_NPUBBYTES))
ad = b"validator-r11-aead-context"
msg = b"libsodium r11 xchacha20poly1305 ietf payload"

ct = crypto_aead_xchacha20poly1305_ietf_encrypt(msg, ad, nonce, key)
assert isinstance(ct, bytes)
assert len(ct) == len(msg) + 16, (len(ct), len(msg))
assert ct != msg

pt = crypto_aead_xchacha20poly1305_ietf_decrypt(ct, ad, nonce, key)
assert pt == msg

corrupt = bytearray(ct)
corrupt[0] ^= 0x01
try:
    crypto_aead_xchacha20poly1305_ietf_decrypt(bytes(corrupt), ad, nonce, key)
except CryptoError:
    print("ok")
else:
    raise SystemExit("forged ciphertext was accepted")
PY
