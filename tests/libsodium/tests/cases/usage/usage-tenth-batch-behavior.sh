#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-python3-nacl-blake2b-personal)
    python3 - <<'PYCASE'
from nacl.hash import blake2b
from nacl.encoding import HexEncoder
digest_a = blake2b(b'payload', person=b'validator-app000', encoder=HexEncoder)
digest_b = blake2b(b'payload', person=b'validator-app000', encoder=HexEncoder)
assert digest_a == digest_b
print(digest_a[:16].decode())
PYCASE
    ;;
  usage-python3-nacl-secretbox-key-size)
    python3 - <<'PYCASE'
from nacl.secret import SecretBox
assert SecretBox.KEY_SIZE == 32
print(SecretBox.KEY_SIZE)
PYCASE
    ;;
  usage-python3-nacl-utils-random-large)
    python3 - <<'PYCASE'
from nacl.utils import random
value = random(64)
assert len(value) == 64
print(len(value))
PYCASE
    ;;
  usage-python3-nacl-public-key-hex-roundtrip)
    python3 - <<'PYCASE'
from nacl.public import PrivateKey
from nacl.encoding import HexEncoder
priv = PrivateKey.generate()
hex_pub = priv.public_key.encode(encoder=HexEncoder)
assert len(hex_pub) == 64
print(hex_pub.decode()[:16])
PYCASE
    ;;
  usage-python3-nacl-signing-deterministic)
    python3 - <<'PYCASE'
from nacl.signing import SigningKey
seed = b'\x01' * 32
sk_a = SigningKey(seed)
sk_b = SigningKey(seed)
sig_a = sk_a.sign(b'detsig payload').signature
sig_b = sk_b.sign(b'detsig payload').signature
assert sig_a == sig_b
print(len(sig_a))
PYCASE
    ;;
  usage-php83-sodium-generichash-length)
    php <<'PHP'
<?php
$h = sodium_crypto_generichash('payload');
if (strlen($h) !== SODIUM_CRYPTO_GENERICHASH_BYTES) { exit(1); }
echo strlen($h), PHP_EOL;
PHP
    ;;
  usage-php83-sodium-shorthash-length)
    php <<'PHP'
<?php
$key = str_repeat("\x42", SODIUM_CRYPTO_SHORTHASH_KEYBYTES);
$h = sodium_crypto_shorthash('payload', $key);
if (strlen($h) !== SODIUM_CRYPTO_SHORTHASH_BYTES) { exit(1); }
echo strlen($h), PHP_EOL;
PHP
    ;;
  usage-php83-sodium-secretbox-detached-roundtrip)
    php <<'PHP'
<?php
$key = sodium_crypto_secretbox_keygen();
$nonce = random_bytes(SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
$msg = 'tenth batch payload';
$cipher = sodium_crypto_secretbox($msg, $nonce, $key);
$plain = sodium_crypto_secretbox_open($cipher, $nonce, $key);
if ($plain !== $msg) { exit(1); }
echo strlen($cipher), PHP_EOL;
PHP
    ;;
  usage-php83-sodium-sign-keypair-bytes)
    php <<'PHP'
<?php
$pair = sodium_crypto_sign_keypair();
if (strlen($pair) !== SODIUM_CRYPTO_SIGN_KEYPAIRBYTES) { exit(1); }
echo strlen($pair), PHP_EOL;
PHP
    ;;
  usage-minisign-pubkey-format)
    out=$(minisign -G -p "$tmpdir/pub.key" -s "$tmpdir/sec.key" -W 2>&1 || true)
    validator_require_file "$tmpdir/pub.key"
    validator_assert_contains "$tmpdir/pub.key" 'minisign public key'
    ;;
  *)
    printf 'unknown libsodium tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
