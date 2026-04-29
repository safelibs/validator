#!/usr/bin/env bash
# @testcase: usage-python3-nacl-sign-verify-hex
# @title: PyNaCl sign verify hex
# @description: Signs and verifies a payload with hex encoding through PyNaCl and verifies the restored plaintext.
# @timeout: 120
# @tags: usage
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-sign-verify-hex"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.encoding import HexEncoder
from nacl.signing import SigningKey
signing_key = SigningKey.generate()
message = b'hex payload'
signed = signing_key.sign(message, encoder=HexEncoder)
restored = signing_key.verify_key.verify(signed, encoder=HexEncoder)
assert restored == message
print(signed[:16].decode())
PYCASE
