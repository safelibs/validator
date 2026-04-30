#!/usr/bin/env bash
# @testcase: usage-python3-nacl-urlsafe-base64-verify-key
# @title: PyNaCl URLSafeBase64Encoder VerifyKey roundtrip
# @description: Builds a SigningKey from a deterministic 32-byte seed, encodes its VerifyKey with nacl.encoding.URLSafeBase64Encoder, asserts the encoded form is URL-safe (no '+' or '/' characters) and decodes back to the same 32 raw bytes via VerifyKey reconstruction, and that the reconstructed key verifies a signature produced by the original signing key.
# @timeout: 60
# @tags: usage, sodium, encoding, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.signing import SigningKey, VerifyKey
from nacl.encoding import URLSafeBase64Encoder, RawEncoder

seed = bytes(range(32))  # deterministic 0x00..0x1f
sk = SigningKey(seed)
raw_vk = sk.verify_key.encode(encoder=RawEncoder)
assert len(raw_vk) == 32

urlsafe = sk.verify_key.encode(encoder=URLSafeBase64Encoder)
assert isinstance(urlsafe, (bytes, bytearray))
text = urlsafe.decode("ascii")
assert "+" not in text and "/" not in text, f"non-urlsafe chars in: {text!r}"

vk_again = VerifyKey(urlsafe, encoder=URLSafeBase64Encoder)
assert vk_again.encode(encoder=RawEncoder) == raw_vk

message = b"urlsafe encoding roundtrip"
signed = sk.sign(message)
assert vk_again.verify(message, signed.signature) == message

print("ok", text)
PY
