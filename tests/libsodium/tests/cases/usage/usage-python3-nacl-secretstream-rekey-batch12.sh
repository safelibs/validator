#!/usr/bin/env bash
# @testcase: usage-python3-nacl-secretstream-rekey-batch12
# @title: PyNaCl secretstream xchacha20poly1305 explicit rekey
# @description: Drives the low-level nacl.bindings secretstream xchacha20poly1305 push state through three chunks (MESSAGE, MESSAGE, FINAL) under a fixed 32-byte key with an explicit crypto_secretstream_xchacha20poly1305_rekey call between chunks, then mirrors the same rekey calls on the pull side and asserts every chunk decrypts back to the original plaintext and that the final tag equals TAG_FINAL.
# @timeout: 180
# @tags: usage, crypto, secretstream, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.bindings as nb

key = bytes([0x37]) * nb.crypto_secretstream_xchacha20poly1305_KEYBYTES

push_state = nb.crypto_secretstream_xchacha20poly1305_state()
header = nb.crypto_secretstream_xchacha20poly1305_init_push(push_state, key)
assert len(header) == nb.crypto_secretstream_xchacha20poly1305_HEADERBYTES

m1 = b"first chunk before rekey"
m2 = b"second chunk after rekey"
m3 = b"final chunk after second rekey"
TAG_M = nb.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE
TAG_F = nb.crypto_secretstream_xchacha20poly1305_TAG_FINAL

c1 = nb.crypto_secretstream_xchacha20poly1305_push(push_state, m1, b"", TAG_M)
nb.crypto_secretstream_xchacha20poly1305_rekey(push_state)
c2 = nb.crypto_secretstream_xchacha20poly1305_push(push_state, m2, b"", TAG_M)
nb.crypto_secretstream_xchacha20poly1305_rekey(push_state)
c3 = nb.crypto_secretstream_xchacha20poly1305_push(push_state, m3, b"", TAG_F)

pull_state = nb.crypto_secretstream_xchacha20poly1305_state()
nb.crypto_secretstream_xchacha20poly1305_init_pull(pull_state, header, key)

p1, t1 = nb.crypto_secretstream_xchacha20poly1305_pull(pull_state, c1, b"")
assert p1 == m1 and t1 == TAG_M
nb.crypto_secretstream_xchacha20poly1305_rekey(pull_state)

p2, t2 = nb.crypto_secretstream_xchacha20poly1305_pull(pull_state, c2, b"")
assert p2 == m2 and t2 == TAG_M
nb.crypto_secretstream_xchacha20poly1305_rekey(pull_state)

p3, t3 = nb.crypto_secretstream_xchacha20poly1305_pull(pull_state, c3, b"")
assert p3 == m3 and t3 == TAG_F

print("ok", len(c1), len(c2), len(c3))
PY
