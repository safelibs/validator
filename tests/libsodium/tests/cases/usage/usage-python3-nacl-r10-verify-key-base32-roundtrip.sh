#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r10-verify-key-base32-roundtrip
# @title: PyNaCl VerifyKey roundtrips through Base32Encoder
# @description: Generates an Ed25519 SigningKey, exports its VerifyKey via nacl.encoding.Base32Encoder, reconstructs the VerifyKey from the encoded form, and asserts the reconstructed key verifies a signature produced by the original SigningKey.
# @timeout: 180
# @tags: usage, crypto, python, encoding
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
from nacl.signing import SigningKey, VerifyKey
from nacl.encoding import Base32Encoder

sk = SigningKey.generate()
vk = sk.verify_key

encoded = vk.encode(encoder=Base32Encoder)
assert isinstance(encoded, bytes), type(encoded)
# Base32 of 32 bytes is 56 chars (no padding suppression by default).
assert len(encoded) >= 32, len(encoded)
# Standard base32 alphabet only.
allowed = set(b"ABCDEFGHIJKLMNOPQRSTUVWXYZ234567=")
assert set(encoded) <= allowed, "non-base32 character in encoded output"

reconstructed = VerifyKey(encoded, encoder=Base32Encoder)
assert reconstructed.encode() == vk.encode(), "reconstructed verify key bytes differ"

msg = b"r10 verify key base32 roundtrip"
signed = sk.sign(msg)
# verify() raises on failure; returns the message on success.
recovered = reconstructed.verify(signed)
assert recovered == msg
print("ok", len(encoded))
PY
