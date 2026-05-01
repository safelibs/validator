#!/usr/bin/env bash
# @testcase: usage-python3-nacl-bindings-shorthash-siphash-batch12
# @title: PyNaCl crypto_shorthash siphash24 deterministic output
# @description: Invokes nacl.bindings.crypto_shorthash on a fixed message with a fixed 16-byte SipHash-2-4 key, asserts the output is exactly crypto_shorthash_BYTES (8) long, that the same inputs produce the same digest, that swapping the key changes the digest, and that swapping the message changes the digest.
# @timeout: 60
# @tags: usage, crypto, shorthash, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.bindings as nb

key_a = bytes([0x11]) * nb.crypto_shorthash_KEYBYTES
key_b = bytes([0x22]) * nb.crypto_shorthash_KEYBYTES
msg = b"validator-shorthash-input"

h1 = nb.crypto_shorthash(msg, key_a)
assert len(h1) == nb.crypto_shorthash_BYTES == 8, len(h1)

h1_again = nb.crypto_shorthash(msg, key_a)
assert h1_again == h1, "siphash not deterministic under same key"

h_other_key = nb.crypto_shorthash(msg, key_b)
assert h_other_key != h1, "different key produced same digest"

h_other_msg = nb.crypto_shorthash(msg + b"!", key_a)
assert h_other_msg != h1, "different message produced same digest"

print("ok", h1.hex())
PY
