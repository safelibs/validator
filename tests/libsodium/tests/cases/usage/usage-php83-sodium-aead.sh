#!/usr/bin/env bash
# @testcase: usage-php83-sodium-aead
# @title: PHP sodium AEAD
# @description: Encrypts and decrypts text with PHP sodium XChaCha20-Poly1305 AEAD helpers.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-aead"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES);
$nonce = random_bytes(SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES);
$cipher = sodium_crypto_aead_xchacha20poly1305_ietf_encrypt('aead payload', 'ad', $nonce, $key);
$plain = sodium_crypto_aead_xchacha20poly1305_ietf_decrypt($cipher, 'ad', $nonce, $key);
if ($plain !== 'aead payload') { exit(1); }
echo $plain, PHP_EOL;
PHP
