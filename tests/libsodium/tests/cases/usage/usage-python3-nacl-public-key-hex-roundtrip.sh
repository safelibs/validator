#!/usr/bin/env bash
# @testcase: usage-python3-nacl-public-key-hex-roundtrip
# @title: python3 nacl public key hex
# @description: Encodes a PyNaCl public key with the HexEncoder and verifies the 64-character hex representation.
# @timeout: 180
# @tags: usage, python, public-key
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-public-key-hex-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.public import PrivateKey
from nacl.encoding import HexEncoder
priv = PrivateKey.generate()
hex_pub = priv.public_key.encode(encoder=HexEncoder)
assert len(hex_pub) == 64
print(hex_pub.decode()[:16])
PYCASE
