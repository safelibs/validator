#!/usr/bin/env bash
# @testcase: usage-python3-nacl-bindings-secretbox-easy
# @title: PyNaCl bindings crypto_secretbox round-trip
# @description: Uses the low-level nacl.bindings.crypto_secretbox and crypto_secretbox_open entry points (PyNaCl 1.5.0 does not export the *_easy aliases; the bare names already use the easy/combined API) with a fixed 32-byte key and 24-byte nonce, asserts the ciphertext is exactly len(plaintext) + crypto_secretbox_MACBYTES, decrypts back to the original plaintext, and confirms that flipping a ciphertext byte makes crypto_secretbox_open raise a CryptoError rather than return corrupted data.
# @timeout: 180
# @tags: usage, crypto, secretbox, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.bindings import (
    crypto_secretbox_KEYBYTES,
    crypto_secretbox_NONCEBYTES,
    crypto_secretbox_MACBYTES,
    crypto_secretbox,
    crypto_secretbox_open,
)
from nacl.exceptions import CryptoError

key = bytes([0x11]) * crypto_secretbox_KEYBYTES
nonce = bytes(range(crypto_secretbox_NONCEBYTES))
plain = b"validator secretbox_easy payload"

ct = crypto_secretbox(plain, nonce, key)
assert len(ct) == len(plain) + crypto_secretbox_MACBYTES, len(ct)

pt = crypto_secretbox_open(ct, nonce, key)
assert pt == plain, pt

# Determinism with fixed key+nonce.
ct2 = crypto_secretbox(plain, nonce, key)
assert ct2 == ct

# Tampering must fail authentication, not return corrupted bytes.
tampered = bytearray(ct)
tampered[-1] ^= 0x01
raised = False
try:
    crypto_secretbox_open(bytes(tampered), nonce, key)
except CryptoError:
    raised = True
assert raised, "tampered ciphertext was accepted"

print("ok", len(ct))
PY
