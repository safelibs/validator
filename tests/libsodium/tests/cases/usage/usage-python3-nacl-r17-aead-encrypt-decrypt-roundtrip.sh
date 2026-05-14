#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r17-aead-encrypt-decrypt-roundtrip
# @title: PyNaCl nacl.bindings AEAD XChaCha20-Poly1305 round-trips a payload with AAD
# @description: Encrypts a fixed payload with associated data using nacl.bindings.crypto_aead_xchacha20poly1305_ietf_encrypt under a random 32-byte key and 24-byte nonce, asserts the ciphertext length equals plaintext+16 (Poly1305 tag) bytes, decrypts with the matching call and asserts the recovered plaintext equals the original byte-for-byte.
# @timeout: 60
# @tags: usage, crypto, aead, xchacha20poly1305, python, r17
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.bindings as b
import nacl.utils

key = nacl.utils.random(b.crypto_aead_xchacha20poly1305_ietf_KEYBYTES)
nonce = nacl.utils.random(b.crypto_aead_xchacha20poly1305_ietf_NPUBBYTES)
msg = b"r17 pynacl xchacha aead payload"
aad = b"r17-aad-context"

ct = b.crypto_aead_xchacha20poly1305_ietf_encrypt(msg, aad, nonce, key)
assert isinstance(ct, bytes), type(ct)
assert len(ct) == len(msg) + b.crypto_aead_xchacha20poly1305_ietf_ABYTES, len(ct)

pt = b.crypto_aead_xchacha20poly1305_ietf_decrypt(ct, aad, nonce, key)
assert pt == msg, (pt, msg)
print("ok aead len=%d" % len(ct))
PY
