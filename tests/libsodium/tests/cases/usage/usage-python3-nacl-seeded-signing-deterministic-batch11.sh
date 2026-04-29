#!/usr/bin/env bash
# @testcase: usage-python3-nacl-seeded-signing-deterministic-batch11
# @title: PyNaCl seeded signing deterministic
# @description: Constructs signing keys from a fixed seed and checks deterministic public keys.
# @timeout: 180
# @tags: usage, sodium, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-seeded-signing-deterministic-batch11"
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

seed = b'\x01' * 32
a = SigningKey(seed).verify_key.encode()
b = SigningKey(seed).verify_key.encode()
assert a == b
print(len(a))
PYCASE
