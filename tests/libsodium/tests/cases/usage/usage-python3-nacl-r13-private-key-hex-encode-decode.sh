#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r13-private-key-hex-encode-decode
# @title: PyNaCl PrivateKey.encode/decode round-trips bytes through the hex encoder
# @description: Generates a PyNaCl PrivateKey, encodes it via HexEncoder, reconstructs a second PrivateKey from the hex string with the same encoder, and asserts both objects expose identical raw bytes and produce the same public key.
# @timeout: 120
# @tags: usage, crypto, key, encoding, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
from nacl.public import PrivateKey
from nacl.encoding import HexEncoder

sk1 = PrivateKey.generate()
hex_blob = sk1.encode(HexEncoder)
assert isinstance(hex_blob, bytes)
assert len(hex_blob) == 64
# All hex digits.
hex_blob.decode("ascii")  # must decode cleanly
int(hex_blob, 16)         # must be a valid hex integer

sk2 = PrivateKey(hex_blob, encoder=HexEncoder)
assert bytes(sk1) == bytes(sk2)
assert bytes(sk1.public_key) == bytes(sk2.public_key)
print("ok", len(hex_blob))
PY
