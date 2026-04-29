#!/usr/bin/env bash
# @testcase: usage-python3-nacl-box-roundtrip
# @title: PyNaCl public box round trip
# @description: Encrypts and decrypts a message through a PyNaCl public-key Box and verifies the plaintext round-trips.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-box-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.public import PrivateKey, Box
alice = PrivateKey.generate()
bob = PrivateKey.generate()
box = Box(alice, bob.public_key)
peer = Box(bob, alice.public_key)
nonce = bytes(range(Box.NONCE_SIZE))
cipher = box.encrypt(b"box payload", nonce)
plain = peer.decrypt(cipher)
assert plain == b"box payload"
print(plain.decode())
PY
