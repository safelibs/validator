#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r20-signing-key-verify-key-bytes-length-32
# @title: PyNaCl SigningKey.verify_key.encode returns a 32-byte Ed25519 public key
# @description: Generates a random SigningKey, accesses .verify_key.encode(), asserts the result has length 32 (Ed25519 public-key bytes), asserts the SigningKey.encode() seed length is also 32, and asserts re-deriving from the same SigningKey produces an identical 32-byte verify key, confirming libsodium-backed Ed25519 key sizes.
# @timeout: 60
# @tags: usage, crypto, signing, ed25519, python, r20
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
from nacl.signing import SigningKey

sk = SigningKey.generate()
vk_bytes = sk.verify_key.encode()
sk_bytes = sk.encode()
assert len(vk_bytes) == 32, len(vk_bytes)
assert len(sk_bytes) == 32, len(sk_bytes)
vk_again = sk.verify_key.encode()
assert vk_again == vk_bytes, 'verify key not deterministic'
print('ok vk_len=%d sk_seed_len=%d' % (len(vk_bytes), len(sk_bytes)))
PY
