#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r19-sealed-box-overhead-48
# @title: PyNaCl SealedBox ciphertext is exactly plaintext + 48 bytes of overhead
# @description: Builds a nacl.public.PrivateKey, derives the public key, constructs a nacl.public.SealedBox over the public key only, encrypts a fixed payload, asserts the ciphertext length equals len(plaintext) + 48 (32-byte ephemeral pubkey + 16-byte Poly1305 tag), then constructs a SealedBox over the PrivateKey and asserts decrypt returns the original plaintext byte-for-byte.
# @timeout: 60
# @tags: usage, crypto, sealedbox, python, r19
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
from nacl.public import PrivateKey, PublicKey, SealedBox

sk = PrivateKey.generate()
pk = sk.public_key

msg = b"r19 pynacl sealed box payload xyz"
ct = SealedBox(pk).encrypt(msg)
assert len(ct) == len(msg) + 48, ("ct_len", len(ct))

pt = SealedBox(sk).decrypt(ct)
assert pt == msg, ("pt", pt, msg)
print("ok sealedbox overhead=48 ct=%d" % len(ct))
PY
