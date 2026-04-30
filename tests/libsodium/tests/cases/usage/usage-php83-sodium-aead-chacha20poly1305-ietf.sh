#!/usr/bin/env bash
# @testcase: usage-php83-sodium-aead-chacha20poly1305-ietf
# @title: PHP sodium ChaCha20-Poly1305-IETF AEAD encrypt and decrypt
# @description: Encrypts a fixed payload with sodium_crypto_aead_chacha20poly1305_ietf_encrypt under a deterministic key, nonce, and associated data, decrypts with sodium_crypto_aead_chacha20poly1305_ietf_decrypt, and asserts the recovered plaintext matches and that decryption fails when the AAD is tampered.
# @timeout: 180
# @tags: usage, crypto, aead, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$key = str_repeat("\x33", SODIUM_CRYPTO_AEAD_CHACHA20POLY1305_IETF_KEYBYTES);
$nonce = str_repeat("\x44", SODIUM_CRYPTO_AEAD_CHACHA20POLY1305_IETF_NPUBBYTES);
$aad = "validator-aad";
$plain = "chacha20poly1305 ietf payload";

$cipher = sodium_crypto_aead_chacha20poly1305_ietf_encrypt($plain, $aad, $nonce, $key);
if ($cipher === false) { exit(1); }
if (strlen($cipher) !== strlen($plain) + SODIUM_CRYPTO_AEAD_CHACHA20POLY1305_IETF_ABYTES) { exit(2); }

$decoded = sodium_crypto_aead_chacha20poly1305_ietf_decrypt($cipher, $aad, $nonce, $key);
if ($decoded !== $plain) { exit(3); }

$tampered = sodium_crypto_aead_chacha20poly1305_ietf_decrypt($cipher, "wrong-aad", $nonce, $key);
if ($tampered !== false) { exit(4); }

echo bin2hex(substr($cipher, 0, 8)), PHP_EOL;
PHP
