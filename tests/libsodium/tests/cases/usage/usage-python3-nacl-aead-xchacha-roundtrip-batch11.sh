#!/usr/bin/env bash
# @testcase: usage-python3-nacl-aead-xchacha-roundtrip-batch11
# @title: PyNaCl XChaCha AEAD roundtrip
# @description: Encrypts and decrypts data with XChaCha20-Poly1305 bindings through PyNaCl.
# @timeout: 180
# @tags: usage, sodium, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-aead-xchacha-roundtrip-batch11"
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

key = utils.random(bindings.crypto_aead_xchacha20poly1305_ietf_KEYBYTES)
nonce = utils.random(bindings.crypto_aead_xchacha20poly1305_ietf_NPUBBYTES)
aad = b'header'
cipher = bindings.crypto_aead_xchacha20poly1305_ietf_encrypt(b'aead payload', aad, nonce, key)
plain = bindings.crypto_aead_xchacha20poly1305_ietf_decrypt(cipher, aad, nonce, key)
assert plain == b'aead payload'
print('aead')
PYCASE
