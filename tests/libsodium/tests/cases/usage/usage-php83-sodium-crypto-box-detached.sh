#!/usr/bin/env bash
# @testcase: usage-php83-sodium-crypto-box-detached
# @title: PHP sodium crypto_box_seal with separate seal/open keys
# @description: Drives sodium_crypto_box_seal to produce an anonymous-sender ciphertext for a recipient curve25519 keypair, asserts the ciphertext is exactly plaintext + SODIUM_CRYPTO_BOX_SEALBYTES, that sodium_crypto_box_seal_open with a sodium_crypto_box_keypair_from_secretkey_and_publickey-built keypair recovers the plaintext, and that opening with a wrong recipient secret key returns false. Uses sodium_crypto_box_publickey/secretkey accessors to split and recombine the keypair.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$kp = sodium_crypto_box_keypair();
$pk = sodium_crypto_box_publickey($kp);
$sk = sodium_crypto_box_secretkey($kp);

if (strlen($pk) !== SODIUM_CRYPTO_BOX_PUBLICKEYBYTES) { fwrite(STDERR, "pk len\n"); exit(1); }
if (strlen($sk) !== SODIUM_CRYPTO_BOX_SECRETKEYBYTES) { fwrite(STDERR, "sk len\n"); exit(2); }

$rebuilt = sodium_crypto_box_keypair_from_secretkey_and_publickey($sk, $pk);
if ($rebuilt !== $kp) { fwrite(STDERR, "rebuild mismatch\n"); exit(3); }

$plain = "validator sealed payload";
$cipher = sodium_crypto_box_seal($plain, $pk);
if ($cipher === false) { fwrite(STDERR, "seal failed\n"); exit(4); }
if (strlen($cipher) !== strlen($plain) + SODIUM_CRYPTO_BOX_SEALBYTES) {
    fwrite(STDERR, "seal len mismatch\n"); exit(5);
}

$opened = sodium_crypto_box_seal_open($cipher, $rebuilt);
if ($opened !== $plain) { fwrite(STDERR, "open mismatch\n"); exit(6); }

// Wrong recipient secret -> false.
$other = sodium_crypto_box_keypair();
$bad = sodium_crypto_box_seal_open($cipher, $other);
if ($bad !== false) { fwrite(STDERR, "wrong key opened\n"); exit(7); }

echo "ok ", strlen($cipher), PHP_EOL;
PHP
