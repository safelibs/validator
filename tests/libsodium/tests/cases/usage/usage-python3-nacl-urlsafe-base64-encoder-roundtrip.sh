#!/usr/bin/env bash
# @testcase: usage-python3-nacl-urlsafe-base64-encoder-roundtrip
# @title: PyNaCl URLSafeBase64Encoder roundtrip with KAT
# @description: Encodes a fixed byte string with nacl.encoding.URLSafeBase64Encoder, asserts the output uses the URL-safe alphabet (no '+' or '/' characters and uses '-' and '_' for the appropriate inputs), decodes it back through the same encoder and asserts byte-for-byte equality with the original, and confirms a 32-byte payload round-trips at the expected encoded length.
# @timeout: 180
# @tags: usage, crypto, encoding, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import base64
from nacl.encoding import URLSafeBase64Encoder

# Bytes 0xFB 0xFF are 11111011 11111111: standard base64 produces "+/" in the
# alphabet, URL-safe base64 must emit "-_" instead.
plain = b"\xfb\xff\xbf"
encoded = URLSafeBase64Encoder.encode(plain)
assert isinstance(encoded, bytes)
# Must not contain standard-base64-only characters.
assert b"+" not in encoded, encoded
assert b"/" not in encoded, encoded
# Must contain at least one URL-safe alphabet character.
assert (b"-" in encoded) or (b"_" in encoded), encoded
# Cross-check against stdlib urlsafe_b64encode.
assert encoded == base64.urlsafe_b64encode(plain), encoded

decoded = URLSafeBase64Encoder.decode(encoded)
assert decoded == plain, decoded

# Empty payload round-trips cleanly.
assert URLSafeBase64Encoder.encode(b"") == b""
assert URLSafeBase64Encoder.decode(b"") == b""

# A 32-byte key-sized payload round-trips exactly.
payload = bytes(range(32))
enc = URLSafeBase64Encoder.encode(payload)
# URL-safe base64 of 32 bytes is 44 chars including '=' padding.
assert len(enc) == 44, len(enc)
assert URLSafeBase64Encoder.decode(enc) == payload

print("ok", len(encoded))
PY
