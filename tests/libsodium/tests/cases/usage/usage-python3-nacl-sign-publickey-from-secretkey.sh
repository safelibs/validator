#!/usr/bin/env bash
# @testcase: usage-python3-nacl-sign-publickey-from-secretkey
# @title: PyNaCl signing key from secret bytes
# @description: Reconstructs a PyNaCl signing key from raw secret-key bytes and verifies the restored key can produce a signature accepted by the original verify key.
# @timeout: 120
# @tags: usage
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-sign-publickey-from-secretkey"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.signing import SigningKey
signing_key = SigningKey.generate()
secret_bytes = signing_key.encode()
restored = SigningKey(secret_bytes)
message = b'secretkey payload'
signed = restored.sign(message)
plain = signing_key.verify_key.verify(signed)
assert plain == message
print(secret_bytes[:8].hex())
PYCASE
