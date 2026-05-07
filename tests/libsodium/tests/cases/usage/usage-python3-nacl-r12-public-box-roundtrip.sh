#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r12-public-box-roundtrip
# @title: PyNaCl public Box round-trips between two keypairs
# @description: Generates two PrivateKey instances, builds Box objects in both directions, encrypts a payload with a fixed 24-byte nonce from sender to receiver, decrypts on the receiver side back to the original plaintext, and asserts the ciphertext differs from the input.
# @timeout: 120
# @tags: usage, crypto, box, curve25519, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
from nacl.public import PrivateKey, Box

sk_a = PrivateKey.generate()
sk_b = PrivateKey.generate()

box_ab = Box(sk_a, sk_b.public_key)
box_ba = Box(sk_b, sk_a.public_key)

nonce = bytes([0x77]) * 24
plain = b"pynacl r12 public box payload"

ct = box_ab.encrypt(plain, nonce)
assert bytes(ct) != plain
recovered = box_ba.decrypt(bytes(ct))
assert recovered == plain
print("ok", len(plain))
PY
