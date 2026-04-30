#!/usr/bin/env bash
# @testcase: usage-python3-nacl-signing-from-hex-seed
# @title: PyNaCl SigningKey from hex seed verified via hex VerifyKey
# @description: Builds a PyNaCl SigningKey from a fixed hex-encoded seed, signs a known message, exports the verify key as hex, reconstructs a VerifyKey from that hex, and asserts the signature verifies for the original message and fails for a tampered one.
# @timeout: 180
# @tags: usage, crypto, signature, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.encoding import HexEncoder
from nacl.exceptions import BadSignatureError
from nacl.signing import SigningKey, VerifyKey

seed_hex = b"4242424242424242424242424242424242424242424242424242424242424242"
signing_key = SigningKey(seed_hex, encoder=HexEncoder)
verify_hex = signing_key.verify_key.encode(encoder=HexEncoder)
assert len(verify_hex) == 64

message = b"hex seed signing payload"
signed = signing_key.sign(message)
assert signed.message == message
assert len(signed.signature) == 64

verify_key = VerifyKey(verify_hex, encoder=HexEncoder)
assert verify_key.verify(message, signed.signature) == message

tampered = message + b"!"
try:
    verify_key.verify(tampered, signed.signature)
except BadSignatureError:
    pass
else:
    raise SystemExit("tampered message verified")
print(verify_hex.decode())
PY
