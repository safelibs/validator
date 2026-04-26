#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-python3-nacl-sign-hex)
    python3 - <<'PY'
from nacl.encoding import HexEncoder
from nacl.signing import SigningKey
sk = SigningKey.generate()
signature = sk.sign(b'hex payload').signature.hex()
assert len(signature) == 128
print(signature[:16])
PY
    ;;
  usage-python3-nacl-sha512)
    python3 - <<'PY'
from nacl.encoding import HexEncoder
from nacl.hash import sha512
digest = sha512(b'payload', encoder=HexEncoder).decode()
assert len(digest) == 128
print(digest[:16])
PY
    ;;
  usage-python3-nacl-pwhash-verify)
    python3 - <<'PY'
from nacl.pwhash import argon2id
hashed = argon2id.str(b'password')
argon2id.verify(hashed, b'password')
print(hashed.decode().split('$')[1])
PY
    ;;
  usage-python3-nacl-secretbox-memoryview)
    python3 - <<'PY'
from nacl.secret import SecretBox
key = b'4' * SecretBox.KEY_SIZE
box = SecretBox(key)
payload = memoryview(b'memory payload')
cipher = box.encrypt(payload)
assert box.decrypt(cipher) == b'memory payload'
print(len(cipher))
PY
    ;;
  usage-python3-nacl-random-size)
    python3 - <<'PY'
from nacl.utils import random
value = random(24)
assert len(value) == 24
print(len(value))
PY
    ;;
  usage-php83-sodium-secretbox-roundtrip)
    php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_SECRETBOX_KEYBYTES);
$nonce = random_bytes(SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
$cipher = sodium_crypto_secretbox('secret payload', $nonce, $key);
$plain = sodium_crypto_secretbox_open($cipher, $nonce, $key);
if ($plain !== 'secret payload') { exit(1); }
echo $plain, PHP_EOL;
PHP
    ;;
  usage-php83-sodium-sign-detached-verify)
    php <<'PHP'
<?php
$pair = sodium_crypto_sign_keypair();
$secret = sodium_crypto_sign_secretkey($pair);
$public = sodium_crypto_sign_publickey($pair);
$sig = sodium_crypto_sign_detached('signed payload', $secret);
if (!sodium_crypto_sign_verify_detached($sig, 'signed payload', $public)) { exit(1); }
echo strlen($sig), PHP_EOL;
PHP
    ;;
  usage-php83-sodium-compare-hex2bin)
    php <<'PHP'
<?php
$hex = sodium_bin2hex('payload');
$plain = sodium_hex2bin($hex);
if (sodium_compare($plain, 'payload') !== 0) { exit(1); }
echo $hex, PHP_EOL;
PHP
    ;;
  usage-php83-sodium-randombytes-size)
    php <<'PHP'
<?php
$value = random_bytes(18);
if (strlen($value) !== 18) { exit(1); }
echo strlen($value), PHP_EOL;
PHP
    ;;
  usage-libzmq5-z85-roundtrip)
    cat >"$tmpdir/t.c" <<'C'
#include <zmq.h>
#include <stdio.h>
#include <string.h>
int main(void) {
  unsigned char raw[32];
  unsigned char decoded[32];
  char encoded[41];
  memset(raw, 7, sizeof(raw));
  if (!zmq_z85_encode(encoded, raw, sizeof(raw))) return 1;
  if (!zmq_z85_decode(decoded, encoded)) return 2;
  return memcmp(raw, decoded, sizeof(raw)) == 0 ? 0 : 3;
}
C
    gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
    "$tmpdir/t"
    ;;
  *)
    printf 'unknown libsodium even-more usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
