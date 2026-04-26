#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-python3-nacl-box-roundtrip)
    python3 - <<'PY'
from nacl.public import PrivateKey, Box
alice = PrivateKey.generate()
bob = PrivateKey.generate()
box = Box(alice, bob.public_key)
peer = Box(bob, alice.public_key)
nonce = bytes(range(Box.NONCE_SIZE))
cipher = box.encrypt(b"box payload", nonce)
plain = peer.decrypt(cipher)
assert plain == b"box payload"
print(plain.decode())
PY
    ;;
  usage-python3-nacl-hex-public-key)
    python3 - <<'PY'
from nacl.public import PrivateKey
from nacl.encoding import HexEncoder
key = PrivateKey.generate().public_key.encode(encoder=HexEncoder).decode()
assert len(key) == 64
print(key[:16])
PY
    ;;
  usage-python3-nacl-detached-verify)
    python3 - <<'PY'
from nacl.signing import SigningKey
signing_key = SigningKey.generate()
signature = signing_key.sign(b"detached payload").signature
plain = signing_key.verify_key.verify(b"detached payload", signature)
assert plain == b"detached payload"
print(plain.decode())
PY
    ;;
  usage-python3-nacl-base64-signature)
    python3 - <<'PY'
from nacl.signing import SigningKey
from nacl.encoding import Base64Encoder
signing_key = SigningKey.generate()
signed = signing_key.sign(b"base64 payload", encoder=Base64Encoder)
decoded = Base64Encoder.decode(signed)
assert len(decoded) > len(b"base64 payload")
print(signed[:16].decode())
PY
    ;;
  usage-python3-nacl-secretbox-nonce-size)
    python3 - <<'PY'
from nacl.secret import SecretBox
key = b"3" * SecretBox.KEY_SIZE
box = SecretBox(key)
cipher = box.encrypt(b"nonce-size payload")
assert len(cipher.nonce) == SecretBox.NONCE_SIZE
assert box.decrypt(cipher) == b"nonce-size payload"
print(len(cipher.nonce))
PY
    ;;
  usage-php83-sodium-hex-roundtrip)
    php <<'PHP'
<?php
$hex = sodium_bin2hex("payload");
$plain = sodium_hex2bin($hex);
if ($plain !== "payload") { exit(1); }
echo $hex, PHP_EOL;
PHP
    ;;
  usage-php83-sodium-auth-verify)
    php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_AUTH_KEYBYTES);
$mac = sodium_crypto_auth('auth payload', $key);
if (!sodium_crypto_auth_verify($mac, 'auth payload', $key)) { exit(1); }
echo sodium_bin2hex($mac), PHP_EOL;
PHP
    ;;
  usage-php83-sodium-stream-xor)
    php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_STREAM_KEYBYTES);
$nonce = random_bytes(SODIUM_CRYPTO_STREAM_NONCEBYTES);
$cipher = sodium_crypto_stream_xor('stream payload', $nonce, $key);
$plain = sodium_crypto_stream_xor($cipher, $nonce, $key);
if ($plain !== 'stream payload') { exit(1); }
echo $plain, PHP_EOL;
PHP
    ;;
  usage-php83-sodium-scalarmult-base)
    php <<'PHP'
<?php
$scalar = random_bytes(SODIUM_CRYPTO_SCALARMULT_SCALARBYTES);
$point = sodium_crypto_scalarmult_base($scalar);
if (strlen($point) !== SODIUM_CRYPTO_SCALARMULT_BYTES) { exit(1); }
echo strlen($point), PHP_EOL;
PHP
    ;;
  usage-php83-sodium-pad-unpad)
    php <<'PHP'
<?php
$padded = sodium_pad('pad payload', 16);
$plain = sodium_unpad($padded, 16);
if ($plain !== 'pad payload') { exit(1); }
echo $plain, PHP_EOL;
PHP
    ;;
  *)
    printf 'unknown libsodium additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
