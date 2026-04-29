#!/usr/bin/env bash
# @testcase: usage-python3-nacl-signature-tamper-fails-batch11
# @title: PyNaCl signature tamper failure
# @description: Signs a message with PyNaCl and checks a tampered signature fails verification.
# @timeout: 180
# @tags: usage, sodium, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-signature-tamper-fails-batch11"
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

key = SigningKey.generate()
signed = bytearray(key.sign(b'payload'))
signed[-1] ^= 1
expect_crypto_error(lambda: key.verify_key.verify(bytes(signed)))
PYCASE
