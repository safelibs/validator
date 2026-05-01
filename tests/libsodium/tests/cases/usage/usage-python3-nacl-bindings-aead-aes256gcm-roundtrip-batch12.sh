#!/usr/bin/env bash
# @testcase: usage-python3-nacl-bindings-aead-aes256gcm-roundtrip-batch12
# @title: PyNaCl AES-256-GCM AEAD capability-gated round-trip
# @description: Calls nacl.bindings.crypto_aead_aes256gcm_is_available; when the backing CPU and libsodium build expose hardware AES-GCM, encrypts a fixed payload with a fixed 32-byte key, 12-byte nonce, and AAD, asserts ciphertext length equals plaintext + ABYTES and decrypts back to the original; when unavailable, prints a skip marker and exits zero so the case stays self-contained on either CPU.
# @timeout: 120
# @tags: usage, crypto, aead, aes, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.bindings as nb

if not nb.crypto_aead_aes256gcm_is_available():
    print("aes256gcm-available 0")
    print("ok skipped (hardware/libsodium lacks aes256gcm)")
    raise SystemExit(0)

print("aes256gcm-available 1")
key = bytes([0x33]) * nb.crypto_aead_aes256gcm_KEYBYTES
nonce = bytes([0x77]) * nb.crypto_aead_aes256gcm_NPUBBYTES
aad = b"validator-aad"
plain = b"aes-256-gcm aead payload"

ct = nb.crypto_aead_aes256gcm_encrypt(plain, aad, nonce, key)
assert len(ct) == len(plain) + nb.crypto_aead_aes256gcm_ABYTES, len(ct)

pt = nb.crypto_aead_aes256gcm_decrypt(ct, aad, nonce, key)
assert pt == plain, pt

# Wrong AAD must raise.
try:
    nb.crypto_aead_aes256gcm_decrypt(ct, b"wrong-aad", nonce, key)
except Exception:
    pass
else:
    raise SystemExit("decrypt under wrong AAD did not fail")

print("ok", len(ct))
PY
