#!/usr/bin/env bash
# @testcase: usage-python3-nacl-verify-key-bytes
# @title: PyNaCl verify key bytes
# @description: Signs a message with PyNaCl and reconstructs the verify key from bytes.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-verify-key-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.signing import SigningKey, VerifyKey
sk = SigningKey.generate()
signed = sk.sign(b"verify payload")
vk = VerifyKey(bytes(sk.verify_key))
assert vk.verify(signed) == b"verify payload"
print("verified")
PY
