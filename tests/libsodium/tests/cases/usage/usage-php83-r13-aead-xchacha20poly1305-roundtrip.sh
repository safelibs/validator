#!/usr/bin/env bash
# @testcase: usage-php83-r13-aead-xchacha20poly1305-roundtrip
# @title: PHP sodium_crypto_aead_xchacha20poly1305_ietf encrypt/decrypt round-trips with AAD
# @description: Encrypts a payload with sodium_crypto_aead_xchacha20poly1305_ietf_encrypt under a fixed 32-byte key, 24-byte nonce, and explicit additional-data string, decrypts it back, and asserts the recovered plaintext matches the original.
# @timeout: 60
# @tags: usage, crypto, aead, xchacha20poly1305, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$key = str_repeat("\x44", SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES);
$nonce = str_repeat("\x55", SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES);
$plain = "php r13 xchacha20poly1305 payload";
$ad = "r13-aad";

$ct = sodium_crypto_aead_xchacha20poly1305_ietf_encrypt($plain, $ad, $nonce, $key);
if ($ct === $plain) { fwrite(STDERR, "ct == plain\n"); exit(1); }

$pt = sodium_crypto_aead_xchacha20poly1305_ietf_decrypt($ct, $ad, $nonce, $key);
if ($pt !== $plain) { fwrite(STDERR, "round-trip mismatch\n"); exit(1); }

// Wrong AAD must fail (returns false).
$bad = sodium_crypto_aead_xchacha20poly1305_ietf_decrypt($ct, "wrong-ad", $nonce, $key);
if ($bad !== false) { fwrite(STDERR, "wrong AAD accepted\n"); exit(1); }
echo "ok\n";
'
