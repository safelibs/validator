#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r13-ed25519-sign-attached-verify
# @title: PyNaCl SigningKey.sign produces a SignedMessage whose VerifyKey.verify recovers the message
# @description: Builds a SigningKey from a fixed 32-byte seed, signs a payload to produce a SignedMessage with sig and message attributes, asserts the signature length is 64 bytes, verifies via VerifyKey.verify(SignedMessage), and confirms a flipped-byte signature raises BadSignatureError.
# @timeout: 120
# @tags: usage, crypto, sign, ed25519, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
from nacl.signing import SigningKey
from nacl.exceptions import BadSignatureError

seed = bytes([0x42]) * 32
sk = SigningKey(seed)
vk = sk.verify_key

msg = b"pynacl r13 ed25519 attached signature"
signed = sk.sign(msg)
assert signed.message == msg
assert len(signed.signature) == 64

recovered = vk.verify(signed)
assert recovered == msg

# Flip one byte in the signature; verify must raise.
mutated = bytearray(signed.signature)
mutated[0] ^= 0x01
try:
    vk.verify(msg, bytes(mutated))
except BadSignatureError:
    pass
else:
    raise SystemExit("tampered signature was accepted")
print("ok", len(msg))
PY
