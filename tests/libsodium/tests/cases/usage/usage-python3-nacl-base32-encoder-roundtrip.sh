#!/usr/bin/env bash
# @testcase: usage-python3-nacl-base32-encoder-roundtrip
# @title: PyNaCl Base32Encoder encode/decode roundtrip
# @description: Encodes a fixed byte string with nacl.encoding.Base32Encoder and asserts the encoded form matches the canonical RFC 4648 base32 KAT, then decodes it back through the same encoder and asserts the bytes match the original.
# @timeout: 180
# @tags: usage, crypto, encoding, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.encoding import Base32Encoder

# RFC 4648 examples: "foobar" -> MZXW6YTBOI======
plain = b"foobar"
encoded = Base32Encoder.encode(plain)
assert encoded == b"MZXW6YTBOI======", encoded
decoded = Base32Encoder.decode(encoded)
assert decoded == plain, decoded

# Empty input must round-trip cleanly.
assert Base32Encoder.encode(b"") == b""
assert Base32Encoder.decode(b"") == b""

# A 32-byte payload (typical key length) round-trips bit-exact.
payload = bytes(range(32))
enc = Base32Encoder.encode(payload)
assert isinstance(enc, bytes)
# Base32 of 32 bytes is 56 characters with no padding (32*8/5 = 51.2 -> 56 with padding chars).
assert len(enc) == 56, len(enc)
assert Base32Encoder.decode(enc) == payload

print("ok", len(encoded))
PY
