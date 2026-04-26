#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-python3-nacl-signing-key-bytes)
    python3 - <<'PYCASE'
from nacl.signing import SigningKey
seed = SigningKey.generate().encode()
assert len(seed) == 32
print(len(seed))
PYCASE
    ;;
  usage-python3-nacl-verify-key-base64)
    python3 - <<'PYCASE'
from nacl.encoding import Base64Encoder
from nacl.signing import SigningKey
value = SigningKey.generate().verify_key.encode(encoder=Base64Encoder).decode()
assert len(value) > 40
print(value[:16])
PYCASE
    ;;
  usage-python3-nacl-blake2b-raw-digest)
    python3 - <<'PYCASE'
from nacl.encoding import RawEncoder
from nacl.hash import blake2b
digest = blake2b(b'payload', encoder=RawEncoder)
assert len(digest) == 32
print(len(digest))
PYCASE
    ;;
  usage-python3-nacl-sealed-box-empty)
    python3 - <<'PYCASE'
from nacl.public import PrivateKey, SealedBox
recipient = PrivateKey.generate()
sealed = SealedBox(recipient.public_key).encrypt(b'')
plain = SealedBox(recipient).decrypt(sealed)
assert plain == b''
print(len(sealed))
PYCASE
    ;;
  usage-python3-nacl-secretbox-base64)
    python3 - <<'PYCASE'
from nacl.encoding import Base64Encoder
from nacl.secret import SecretBox
box = SecretBox(b'5' * SecretBox.KEY_SIZE)
cipher = box.encrypt(b'base64 payload', encoder=Base64Encoder)
plain = box.decrypt(cipher, encoder=Base64Encoder)
assert plain == b'base64 payload'
print(cipher[:16].decode())
PYCASE
    ;;
  usage-php83-sodium-generichash-state)
    php <<'PHP'
<?php
$state = sodium_crypto_generichash_init('', 16);
sodium_crypto_generichash_update($state, 'part-one');
sodium_crypto_generichash_update($state, '-part-two');
$hash = sodium_crypto_generichash_final($state, 16);
if (strlen($hash) !== 16) { exit(1); }
echo sodium_bin2hex($hash), PHP_EOL;
PHP
    ;;
  usage-php83-sodium-sign-seed-keypair)
    php <<'PHP'
<?php
$seed = str_repeat("\x01", SODIUM_CRYPTO_SIGN_SEEDBYTES);
$keypair = sodium_crypto_sign_seed_keypair($seed);
$public = sodium_crypto_sign_publickey($keypair);
if (strlen($public) !== SODIUM_CRYPTO_SIGN_PUBLICKEYBYTES) { exit(1); }
echo strlen($public), PHP_EOL;
PHP
    ;;
  usage-php83-sodium-base64-urlsafe)
    php <<'PHP'
<?php
$encoded = sodium_bin2base64("payload\xff", SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING);
$decoded = sodium_base642bin($encoded, SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING);
if ($decoded !== "payload\xff") { exit(1); }
echo $encoded, PHP_EOL;
PHP
    ;;
  usage-php83-sodium-increment)
    php <<'PHP'
<?php
$value = str_repeat("\x00", 8);
sodium_increment($value);
if (ord($value[0]) !== 1) { exit(1); }
echo ord($value[0]), PHP_EOL;
PHP
    ;;
  usage-php83-sodium-memcmp)
    php <<'PHP'
<?php
if (sodium_memcmp('abcd', 'abcd') !== 0) { exit(1); }
if (sodium_memcmp('abcd', 'abce') === 0) { exit(1); }
echo "memcmp\n";
PHP
    ;;
  *)
    printf 'unknown libsodium further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
