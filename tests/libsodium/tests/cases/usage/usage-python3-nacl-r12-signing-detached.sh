#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r12-signing-detached
# @title: PyNaCl SigningKey produces a verifiable Ed25519 detached signature
# @description: Creates a SigningKey from a fixed 32-byte seed, signs a payload, asserts the signature length is 64 bytes, verifies the signature with the matching VerifyKey, and confirms a tampered signature triggers BadSignatureError on verify.
# @timeout: 120
# @tags: usage, crypto, signing, ed25519, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.signing
import nacl.exceptions

seed = bytes([0x42]) * 32
sk = nacl.signing.SigningKey(seed)
vk = sk.verify_key

msg = b"pynacl r12 signing payload"
signed = sk.sign(msg)
sig = signed.signature
assert len(sig) == 64, len(sig)

# Round-trip verify.
assert vk.verify(msg, sig) == msg

# Tampered signature must raise.
tampered = bytearray(sig)
tampered[0] ^= 0x01
try:
    vk.verify(msg, bytes(tampered))
except nacl.exceptions.BadSignatureError:
    pass
else:
    raise SystemExit("tampered signature was accepted")
print("ok")
PY
