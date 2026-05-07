#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r14-box-random-nonce-distinct-ct
# @title: PyNaCl Box.encrypt with random nonces yields distinct ciphertexts that both decrypt
# @description: Generates two PrivateKey instances, builds Box objects in both directions, encrypts the same plaintext twice without supplying a nonce so the binding selects a fresh random nonce each time, asserts the two ciphertexts differ, and asserts both decrypt back to the identical original plaintext on the receiver side.
# @timeout: 120
# @tags: usage, crypto, box, nonce, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
from nacl.public import PrivateKey, Box

sk_a = PrivateKey.generate()
sk_b = PrivateKey.generate()

box_ab = Box(sk_a, sk_b.public_key)
box_ba = Box(sk_b, sk_a.public_key)

plain = b"pynacl r14 random-nonce payload"

ct1 = box_ab.encrypt(plain)
ct2 = box_ab.encrypt(plain)

# EncryptedMessage objects compare bytewise; under fresh random nonces they
# must differ (nonce embedded inside the encoded message).
assert bytes(ct1) != bytes(ct2), "random nonces produced identical ciphertexts"

# Both ciphertexts decrypt back to the same plaintext.
assert box_ba.decrypt(bytes(ct1)) == plain
assert box_ba.decrypt(bytes(ct2)) == plain
print("ok", len(plain))
PY
