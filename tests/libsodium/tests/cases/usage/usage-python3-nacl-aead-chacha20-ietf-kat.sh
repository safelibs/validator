#!/usr/bin/env bash
# @testcase: usage-python3-nacl-aead-chacha20-ietf-kat
# @title: PyNaCl ChaCha20-Poly1305-IETF AEAD deterministic KAT
# @description: Encrypts a fixed payload with nacl.bindings.crypto_aead_chacha20poly1305_ietf_encrypt under a deterministic 32-byte key, 12-byte nonce, and AAD; asserts the ciphertext length is plaintext+ABYTES, that decryption recovers the plaintext exactly, and that decryption with a flipped AAD raises a CryptoError.
# @timeout: 60
# @tags: usage, sodium, aead, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl import bindings, exceptions

KEYBYTES = bindings.crypto_aead_chacha20poly1305_ietf_KEYBYTES
NPUBBYTES = bindings.crypto_aead_chacha20poly1305_ietf_NPUBBYTES
ABYTES = bindings.crypto_aead_chacha20poly1305_ietf_ABYTES

assert KEYBYTES == 32, KEYBYTES
assert NPUBBYTES == 12, NPUBBYTES

key = bytes([0x55]) * KEYBYTES
nonce = bytes([0x77]) * NPUBBYTES
aad = b"validator-aad"
plaintext = b"chacha20poly1305 ietf KAT payload"

cipher = bindings.crypto_aead_chacha20poly1305_ietf_encrypt(plaintext, aad, nonce, key)
assert len(cipher) == len(plaintext) + ABYTES, (len(cipher), len(plaintext), ABYTES)

# Deterministic for fixed inputs.
cipher2 = bindings.crypto_aead_chacha20poly1305_ietf_encrypt(plaintext, aad, nonce, key)
assert cipher == cipher2, "ietf AEAD ciphertext not deterministic for fixed key/nonce"

recovered = bindings.crypto_aead_chacha20poly1305_ietf_decrypt(cipher, aad, nonce, key)
assert recovered == plaintext, recovered

try:
    bindings.crypto_aead_chacha20poly1305_ietf_decrypt(cipher, b"different-aad", nonce, key)
except exceptions.CryptoError:
    pass
else:
    raise SystemExit("decrypt with wrong AAD did not fail")

print("ok", cipher[:8].hex())
PY
