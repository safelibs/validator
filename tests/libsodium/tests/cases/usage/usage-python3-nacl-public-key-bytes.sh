#!/usr/bin/env bash
# @testcase: usage-python3-nacl-public-key-bytes
# @title: PyNaCl public key bytes
# @description: Serializes and reconstructs a PyNaCl public key through libsodium-backed key objects.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-public-key-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.public import PrivateKey, PublicKey
private_key = PrivateKey.generate()
public_key = PublicKey(bytes(private_key.public_key))
assert bytes(public_key) == bytes(private_key.public_key)
print(len(bytes(public_key)))
PY
