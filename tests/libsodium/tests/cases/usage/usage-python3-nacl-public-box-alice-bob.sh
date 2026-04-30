#!/usr/bin/env bash
# @testcase: usage-python3-nacl-public-box-alice-bob
# @title: PyNaCl Box Alice-to-Bob encrypt and Bob-side decrypt
# @description: Constructs two PyNaCl PrivateKeys from deterministic raw seeds, encrypts a payload with Box(alice_sk, bob_pk), decrypts on Bob's side with Box(bob_sk, alice_pk), and asserts the recovered plaintext matches exactly.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.public import Box, PrivateKey

alice_sk = PrivateKey(b"\x11" * 32)
bob_sk = PrivateKey(b"\x22" * 32)
alice_pk = alice_sk.public_key
bob_pk = bob_sk.public_key

plaintext = b"alice -> bob over libsodium box"
sender = Box(alice_sk, bob_pk)
encrypted = sender.encrypt(plaintext)
assert encrypted.ciphertext != plaintext
assert len(encrypted.nonce) == Box.NONCE_SIZE

receiver = Box(bob_sk, alice_pk)
recovered = receiver.decrypt(encrypted)
assert recovered == plaintext, recovered

# also verify decrypt works from raw nonce + ciphertext bytes
recovered2 = receiver.decrypt(encrypted.ciphertext, encrypted.nonce)
assert recovered2 == plaintext
print("ok", len(recovered))
PY
