#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-python3-nacl-sha512-digest-hex)
    python3 - <<'PYCASE'
from nacl.hash import sha512
digest = sha512(b'validator').decode()
assert len(digest) == 128
print(digest[:16])
PYCASE
    ;;
  usage-python3-nacl-random-bytes-length)
    python3 - <<'PYCASE'
from nacl.utils import random
value = random(12)
assert len(value) == 12
print(len(value))
PYCASE
    ;;
  usage-python3-nacl-sign-publickey-from-secretkey)
    python3 - <<'PYCASE'
from nacl.signing import SigningKey
signing_key = SigningKey.generate()
secret_bytes = signing_key.encode()
restored = SigningKey(secret_bytes)
message = b'secretkey payload'
signed = restored.sign(message)
plain = signing_key.verify_key.verify(signed)
assert plain == message
print(secret_bytes[:8].hex())
PYCASE
    ;;
  usage-python3-nacl-secretbox-empty-message)
    python3 - <<'PYCASE'
from nacl.secret import SecretBox
box = SecretBox(b'7' * SecretBox.KEY_SIZE)
cipher = box.encrypt(b'')
plain = box.decrypt(cipher)
assert plain == b''
print(len(cipher))
PYCASE
    ;;
  usage-python3-nacl-sign-verify-hex)
    python3 - <<'PYCASE'
from nacl.encoding import HexEncoder
from nacl.signing import SigningKey
signing_key = SigningKey.generate()
message = b'hex payload'
signed = signing_key.sign(message, encoder=HexEncoder)
restored = signing_key.verify_key.verify(signed, encoder=HexEncoder)
assert restored == message
print(signed[:16].decode())
PYCASE
    ;;
  usage-php83-sodium-sign-publickey-from-secretkey)
    php <<'PHP'
<?php
$pair = sodium_crypto_sign_keypair();
$secret = sodium_crypto_sign_secretkey($pair);
$public = sodium_crypto_sign_publickey($pair);
$derived = sodium_crypto_sign_publickey_from_secretkey($secret);
if ($derived !== $public) { exit(1); }
echo strlen($derived), PHP_EOL;
PHP
    ;;
  usage-php83-sodium-bin2hex-roundtrip)
    php <<'PHP'
<?php
$hex = sodium_bin2hex("payload\x00");
$raw = sodium_hex2bin($hex);
if ($raw !== "payload\x00") { exit(1); }
echo $hex, PHP_EOL;
PHP
    ;;
  usage-php83-sodium-add)
    php <<'PHP'
<?php
$value = str_repeat("\x00", 8);
$delta = "\x02" . str_repeat("\x00", 7);
sodium_add($value, $delta);
if (ord($value[0]) !== 2) { exit(1); }
echo ord($value[0]), PHP_EOL;
PHP
    ;;
  usage-php83-sodium-add-carry)
    php <<'PHP'
<?php
$value = "\xff\x00" . str_repeat("\x00", 6);
$delta = "\x01" . str_repeat("\x00", 7);
sodium_add($value, $delta);
if (ord($value[0]) !== 0 || ord($value[1]) !== 1) { exit(1); }
echo ord($value[0]), ':', ord($value[1]), PHP_EOL;
PHP
    ;;
  usage-php83-sodium-stream-zero-xor)
    php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_STREAM_KEYBYTES);
$nonce = random_bytes(SODIUM_CRYPTO_STREAM_NONCEBYTES);
$stream = sodium_crypto_stream(24, $nonce, $key);
$xor = sodium_crypto_stream_xor(str_repeat("\x00", 24), $nonce, $key);
if ($stream !== $xor) { exit(1); }
echo strlen($stream), PHP_EOL;
PHP
    ;;
  *)
    printf 'unknown libsodium expanded usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
