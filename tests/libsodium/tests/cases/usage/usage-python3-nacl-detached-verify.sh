#!/usr/bin/env bash
# @testcase: usage-python3-nacl-detached-verify
# @title: PyNaCl detached verify
# @description: Signs a message with PyNaCl, verifies the detached signature, and confirms the original plaintext is returned.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-detached-verify"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.signing import SigningKey
signing_key = SigningKey.generate()
signature = signing_key.sign(b"detached payload").signature
plain = signing_key.verify_key.verify(b"detached payload", signature)
assert plain == b"detached payload"
print(plain.decode())
PY
