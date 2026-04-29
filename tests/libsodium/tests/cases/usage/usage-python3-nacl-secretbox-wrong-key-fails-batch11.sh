#!/usr/bin/env bash
# @testcase: usage-python3-nacl-secretbox-wrong-key-fails-batch11
# @title: PyNaCl SecretBox wrong key failure
# @description: Encrypts with SecretBox and checks decryption with a different key fails.
# @timeout: 180
# @tags: usage, sodium, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-secretbox-wrong-key-fails-batch11"
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

box = SecretBox(utils.random(SecretBox.KEY_SIZE))
bad = SecretBox(utils.random(SecretBox.KEY_SIZE))
token = box.encrypt(b'payload')
expect_crypto_error(lambda: bad.decrypt(token))
PYCASE
