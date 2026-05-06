#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r10-box-shared-key-symmetric
# @title: PyNaCl Box.shared_key is symmetric across both peers
# @description: Constructs nacl.public.Box on both Alice and Bob using their PrivateKey/PublicKey pairs, calls Box.shared_key() on each side, and asserts the 32-byte raw secrets are byte-identical (Curve25519 ECDH symmetry).
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
from nacl.public import PrivateKey, Box

alice_sk = PrivateKey.generate()
bob_sk = PrivateKey.generate()

box_a = Box(alice_sk, bob_sk.public_key)
box_b = Box(bob_sk, alice_sk.public_key)

shared_a = box_a.shared_key()
shared_b = box_b.shared_key()

assert isinstance(shared_a, bytes), type(shared_a)
assert len(shared_a) == 32, len(shared_a)
assert shared_a == shared_b, "shared keys must match across peers"

# A third unrelated key must derive a different shared secret.
charlie_sk = PrivateKey.generate()
shared_c = Box(charlie_sk, bob_sk.public_key).shared_key()
assert shared_c != shared_a, "unrelated peer must yield a different secret"
print("ok", len(shared_a))
PY
