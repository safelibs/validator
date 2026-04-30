#!/usr/bin/env bash
# @testcase: usage-python3-nacl-bindings-crypto-box-sender-recipient
# @title: PyNaCl bindings crypto_box sender/recipient roundtrip
# @description: Generates two libsodium curve25519 keypairs through nacl.bindings.crypto_box_keypair, encrypts a payload with crypto_box(sender_sk, recipient_pk) under a 24-byte nonce, decrypts it on the recipient side with crypto_box_open(recipient_sk, sender_pk), and asserts the plaintext is recovered exactly. Then flips a ciphertext byte and confirms decryption raises through the binding-level CryptoError rather than silently returning corrupted plaintext.
# @timeout: 180
# @tags: usage, crypto, box, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl import bindings as b
from nacl.exceptions import CryptoError

sender_pk, sender_sk = b.crypto_box_keypair()
recip_pk, recip_sk = b.crypto_box_keypair()
assert len(sender_pk) == b.crypto_box_PUBLICKEYBYTES
assert len(sender_sk) == b.crypto_box_SECRETKEYBYTES
assert sender_pk != recip_pk

nonce = bytes(range(b.crypto_box_NONCEBYTES))
plaintext = b"pynacl bindings crypto_box payload"

# crypto_box may live as crypto_box or crypto_box_easy depending on binding shape.
encrypt = getattr(b, "crypto_box", None) or getattr(b, "crypto_box_easy")
decrypt = getattr(b, "crypto_box_open", None) or getattr(b, "crypto_box_open_easy")

ciphertext = encrypt(plaintext, nonce, recip_pk, sender_sk)
assert ciphertext != plaintext
# MAC byte count: prefer crypto_box_MACBYTES if exposed, otherwise fall back
# to the equivalent SEALBYTES - PUBLICKEYBYTES or the secretbox MAC size
# (both are 16 bytes for the curve25519/xsalsa20/poly1305 construction).
mac_bytes = getattr(b, "crypto_box_MACBYTES", None)
if mac_bytes is None:
    mac_bytes = getattr(b, "crypto_secretbox_MACBYTES", 16)
assert len(ciphertext) == len(plaintext) + mac_bytes

recovered = decrypt(ciphertext, nonce, sender_pk, recip_sk)
assert recovered == plaintext, recovered

# Tamper a single byte: decryption must raise.
tampered = bytearray(ciphertext)
tampered[0] ^= 0xFF
try:
    decrypt(bytes(tampered), nonce, sender_pk, recip_sk)
except CryptoError:
    pass
else:
    raise SystemExit("tampered ciphertext decrypted successfully")

print("ok", len(ciphertext))
PY
