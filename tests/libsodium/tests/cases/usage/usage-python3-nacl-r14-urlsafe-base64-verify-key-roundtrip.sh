#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r14-urlsafe-base64-verify-key-roundtrip
# @title: PyNaCl URLSafeBase64Encoder round-trips a VerifyKey through encode and reconstruction
# @description: Builds a SigningKey from a fixed seed, encodes its VerifyKey with URLSafeBase64Encoder, asserts the encoded form is bytes containing only URL-safe base64 characters, reconstructs a VerifyKey from the encoded form via the same encoder, and asserts the reconstructed key bytes match the original.
# @timeout: 120
# @tags: usage, crypto, encoding, urlsafe-base64, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import re
from nacl.signing import SigningKey, VerifyKey
from nacl.encoding import URLSafeBase64Encoder, RawEncoder

seed = bytes([0x14]) * 32
sk = SigningKey(seed)
vk = sk.verify_key

encoded = vk.encode(encoder=URLSafeBase64Encoder)
assert isinstance(encoded, bytes), type(encoded)
# URL-safe base64 alphabet: A-Z a-z 0-9 _ - and '=' padding.
assert re.fullmatch(rb"[A-Za-z0-9_\-]+={0,2}", encoded), encoded

vk_round = VerifyKey(encoded, encoder=URLSafeBase64Encoder)
assert bytes(vk_round) == bytes(vk), "round-trip mismatch"
assert vk_round.encode(encoder=RawEncoder) == bytes(vk)
print("ok", len(encoded))
PY
