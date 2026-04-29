#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

if case_id == 'usage-python3-nacl-secretbox-wrong-key-fails-batch11':
    box = SecretBox(utils.random(SecretBox.KEY_SIZE))
    bad = SecretBox(utils.random(SecretBox.KEY_SIZE))
    token = box.encrypt(b'payload')
    expect_crypto_error(lambda: bad.decrypt(token))
elif case_id == 'usage-python3-nacl-signature-tamper-fails-batch11':
    key = SigningKey.generate()
    signed = bytearray(key.sign(b'payload'))
    signed[-1] ^= 1
    expect_crypto_error(lambda: key.verify_key.verify(bytes(signed)))
elif case_id == 'usage-python3-nacl-public-box-wrong-key-fails-batch11':
    alice = PrivateKey.generate()
    bob = PrivateKey.generate()
    mallory = PrivateKey.generate()
    token = Box(alice, bob.public_key).encrypt(b'box payload')
    expect_crypto_error(lambda: Box(mallory, alice.public_key).decrypt(token))
elif case_id == 'usage-python3-nacl-aead-xchacha-roundtrip-batch11':
    key = utils.random(bindings.crypto_aead_xchacha20poly1305_ietf_KEYBYTES)
    nonce = utils.random(bindings.crypto_aead_xchacha20poly1305_ietf_NPUBBYTES)
    aad = b'header'
    cipher = bindings.crypto_aead_xchacha20poly1305_ietf_encrypt(b'aead payload', aad, nonce, key)
    plain = bindings.crypto_aead_xchacha20poly1305_ietf_decrypt(cipher, aad, nonce, key)
    assert plain == b'aead payload'
    print('aead')
elif case_id == 'usage-python3-nacl-pwhash-str-roundtrip-batch11':
    password = b'correct horse battery staple'
    hashed = pwhash.argon2id.str(password)
    assert pwhash.argon2id.verify(hashed, password)
    print('pwhash')
elif case_id == 'usage-python3-nacl-blake2b-keyed-length-batch11':
    digest = hash.blake2b(b'payload', key=b'k' * 32, digest_size=32, encoder=encoding.HexEncoder)
    assert len(digest) == 64
    print(digest.decode())
elif case_id == 'usage-python3-nacl-hex-encoder-roundtrip-batch11':
    raw = b'encoder payload'
    encoded = encoding.HexEncoder.encode(raw)
    assert encoding.HexEncoder.decode(encoded) == raw
    print(encoded.decode())
elif case_id == 'usage-python3-nacl-seeded-signing-deterministic-batch11':
    seed = b'\x01' * 32
    a = SigningKey(seed).verify_key.encode()
    b = SigningKey(seed).verify_key.encode()
    assert a == b
    print(len(a))
elif case_id == 'usage-python3-nacl-public-key-hex-construct-batch11':
    key = PrivateKey.generate().public_key
    encoded = key.encode(encoder=encoding.HexEncoder)
    rebuilt = PublicKey(encoded, encoder=encoding.HexEncoder)
    assert rebuilt.encode() == key.encode()
    print(len(encoded))
elif case_id == 'usage-python3-nacl-bindings-constant-sizes-batch11':
    assert bindings.crypto_secretbox_KEYBYTES == SecretBox.KEY_SIZE
    assert bindings.crypto_secretbox_NONCEBYTES > 0
    print(bindings.crypto_secretbox_KEYBYTES, bindings.crypto_secretbox_NONCEBYTES)
else:
    raise SystemExit(f'unknown libsodium eleventh-batch usage case: {case_id}')
PYCASE
