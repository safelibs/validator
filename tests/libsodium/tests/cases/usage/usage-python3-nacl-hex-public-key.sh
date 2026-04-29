#!/usr/bin/env bash
# @testcase: usage-python3-nacl-hex-public-key
# @title: PyNaCl hex public key
# @description: Encodes a PyNaCl public key as hexadecimal and verifies the expected encoded length.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-hex-public-key"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.public import PrivateKey
from nacl.encoding import HexEncoder
key = PrivateKey.generate().public_key.encode(encoder=HexEncoder).decode()
assert len(key) == 64
print(key[:16])
PY
