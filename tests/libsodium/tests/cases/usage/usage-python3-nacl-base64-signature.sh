#!/usr/bin/env bash
# @testcase: usage-python3-nacl-base64-signature
# @title: PyNaCl base64 signature
# @description: Produces a base64-encoded signed message with PyNaCl and verifies encoded output is emitted.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-base64-signature"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.signing import SigningKey
from nacl.encoding import Base64Encoder
signing_key = SigningKey.generate()
signed = signing_key.sign(b"base64 payload", encoder=Base64Encoder)
decoded = Base64Encoder.decode(signed)
assert len(decoded) > len(b"base64 payload")
print(signed[:16].decode())
PY
