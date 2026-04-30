#!/usr/bin/env bash
# @testcase: usage-php83-sodium-kx-keypair-accessors
# @title: PHP sodium kx keypair secretkey/publickey accessors
# @description: Generates a key-exchange keypair with sodium_crypto_kx_keypair, extracts the secret half via sodium_crypto_kx_secretkey and the public half via sodium_crypto_kx_publickey, asserts each component has the documented 32-byte length and the documented total keypair size, that the accessor outputs are stable for a given keypair, and that the secret and public halves differ.
# @timeout: 180
# @tags: usage, crypto, kx, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$kp = sodium_crypto_kx_keypair();
if (strlen($kp) !== SODIUM_CRYPTO_KX_KEYPAIRBYTES) {
    fwrite(STDERR, "unexpected keypair length: " . strlen($kp) . PHP_EOL);
    exit(10);
}

$sk = sodium_crypto_kx_secretkey($kp);
$pk = sodium_crypto_kx_publickey($kp);

if (strlen($sk) !== SODIUM_CRYPTO_KX_SECRETKEYBYTES) { exit(11); }
if (strlen($pk) !== SODIUM_CRYPTO_KX_PUBLICKEYBYTES) { exit(12); }
if (SODIUM_CRYPTO_KX_SECRETKEYBYTES !== 32) { exit(13); }
if (SODIUM_CRYPTO_KX_PUBLICKEYBYTES !== 32) { exit(14); }

if (sodium_memcmp($sk, $pk) === 0) { exit(15); }

// Accessors must be stable for the same keypair.
$sk2 = sodium_crypto_kx_secretkey($kp);
$pk2 = sodium_crypto_kx_publickey($kp);
if (sodium_memcmp($sk, $sk2) !== 0) { exit(16); }
if (sodium_memcmp($pk, $pk2) !== 0) { exit(17); }

echo bin2hex(substr($pk, 0, 8)), PHP_EOL;
PHP
