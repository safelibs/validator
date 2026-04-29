#!/usr/bin/env bash
# @testcase: usage-python3-nacl-public-key-hex-construct-batch11
# @title: PyNaCl public key hex construct
# @description: Reconstructs a public key from a hex encoding through PyNaCl.
# @timeout: 180
# @tags: usage, sodium, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-public-key-hex-construct-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id"
import sys
from nacl import bindings, encoding, exceptions, hash, pwhash, utils
from nacl.public import Box, PrivateKey, PublicKey
from nacl.secret import SecretBox
from nacl.signing import SigningKey

case_id = sys.argv[1]

def expect_crypto_error(fn):
    try:
        fn()
    except Exception as exc:
        if isinstance(exc, (exceptions.CryptoError, exceptions.BadSignatureError)):
            print(type(exc).__name__)
            return
        raise
    raise AssertionError('expected crypto failure')

key = PrivateKey.generate().public_key
encoded = key.encode(encoder=encoding.HexEncoder)
rebuilt = PublicKey(encoded, encoder=encoding.HexEncoder)
assert rebuilt.encode() == key.encode()
print(len(encoded))
PYCASE
