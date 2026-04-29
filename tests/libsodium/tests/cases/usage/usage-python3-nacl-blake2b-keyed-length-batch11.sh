#!/usr/bin/env bash
# @testcase: usage-python3-nacl-blake2b-keyed-length-batch11
# @title: PyNaCl keyed BLAKE2b length
# @description: Computes a keyed BLAKE2b digest through PyNaCl and checks the hex length.
# @timeout: 180
# @tags: usage, sodium, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-blake2b-keyed-length-batch11"
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

digest = hash.blake2b(b'payload', key=b'k' * 32, digest_size=32, encoder=encoding.HexEncoder)
assert len(digest) == 64
print(digest.decode())
PYCASE
