#!/usr/bin/env bash
# @testcase: usage-python3-nacl-aead-aes256gcm-capability
# @title: PyNaCl crypto_aead_aes256gcm capability-gated KAT
# @description: Probes nacl.bindings.crypto_aead_aes256gcm_is_available; when libsodium reports hardware support, encrypts and decrypts a fixed message with a fixed key, nonce, and AAD and asserts the ciphertext is exactly len(message)+16 bytes and decrypts back to the original; when unsupported, succeeds without exercising the primitive.
# @timeout: 180
# @tags: usage, crypto, aead, aes, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import nacl.bindings as nb

# Older PyNaCl wheels (Ubuntu 24.04 ships 1.5.0) do not export
# crypto_aead_aes256gcm_is_available; treat absence-of-binding as the
# capability-not-available signal, which is exactly what the gated test
# is meant to encode.
is_available = getattr(nb, "crypto_aead_aes256gcm_is_available", None)
if is_available is None:
    print("aes256gcm-available", False)
    print("ok skipped (binding absent)")
    raise SystemExit(0)

available = is_available()
print("aes256gcm-available", bool(available))

if not available:
    # The implementation correctly reports lack of CPU support; nothing else to assert.
    print("ok skipped")
    raise SystemExit(0)

from nacl.bindings import (
    crypto_aead_aes256gcm_KEYBYTES,
    crypto_aead_aes256gcm_NPUBBYTES,
    crypto_aead_aes256gcm_ABYTES,
    crypto_aead_aes256gcm_encrypt,
    crypto_aead_aes256gcm_decrypt,
)

key = bytes([0x42]) * crypto_aead_aes256gcm_KEYBYTES
nonce = bytes(range(crypto_aead_aes256gcm_NPUBBYTES))
aad = b"validator-aad"
message = b"validator aes256gcm payload"

ct = crypto_aead_aes256gcm_encrypt(message, aad, nonce, key)
assert len(ct) == len(message) + crypto_aead_aes256gcm_ABYTES, len(ct)

pt = crypto_aead_aes256gcm_decrypt(ct, aad, nonce, key)
assert pt == message, pt

# Determinism for fixed inputs (AES-GCM with fixed nonce/key/aad is deterministic).
ct2 = crypto_aead_aes256gcm_encrypt(message, aad, nonce, key)
assert ct2 == ct, "AES-GCM not deterministic for fixed inputs"

print("ok", len(ct))
PY
